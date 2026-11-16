{ icedosLib, ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          modulesPath,
          pkgs,
          ...
        }:

        let
          inherit (lib)
            hasInfix
            mkDefault
            mkForce
            mkOverride
            ;

          inherit (config.icedos.hardware) kernel;

          mesaOverlay = import ./mesa;

          ps4PackagesOverlay =
            final: prev:
            let
              ps4Pkgs = final.callPackage ./packages.nix { };
            in
            {
              inherit (ps4Pkgs) ps4-bridge ps4-hdmi-keepalive;

              ps4-firmware = final.runCommand "ps4-firmware" { } ''
                mkdir -p $out/lib/firmware
                cp -r --no-preserve=mode ${final.linux_ps4_src}/extra_firmware/. $out/lib/firmware/
                rm -f $out/lib/firmware/.gitignore
              '';
            };
        in
        {
          assertions = [
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "cachyos-kernel";
                });
              message = "The PS4 device profile cannot run CachyOS kernels; disable the cachyos-kernel module.";
            }
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "scx";
                });
              message = "The PS4 device profile does not support sched-ext (scx); disable the scx module.";
            }
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "ryzen";
                });
              message = "The PS4 CPU (AMD Jaguar btver2) is not a Ryzen CPU; disable the ryzen module.";
            }
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "intel";
                });
              message = "The PS4 CPU (AMD Jaguar btver2) is not an Intel CPU; disable the intel module.";
            }
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "zenstates";
                });
              message = "The PS4 CPU does not support zenstates; disable the zenstates module.";
            }
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "zenergy";
                });
              message = "The PS4 CPU does not support zenergy; disable the zenergy module.";
            }
            {
              assertion =
                !(icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/hardware";
                  name = "steamdeck";
                });
              message = "The PS4 device profile cannot be combined with the steamdeck module.";
            }
            {
              assertion =
                kernel.variant == "ps4"
                || (
                  !hasInfix "v3" kernel.variant && !hasInfix "v4" kernel.variant && !hasInfix "znver" kernel.variant
                );
              message = "The PS4 Jaguar CPU only supports up to x86-64-v2 (btver2); cannot use ${kernel.variant}.";
            }
          ];

          # Bootloader: initScript only, no grub/systemd-boot install.
          boot.loader = {
            initScript.enable = true;
            grub.enable = mkForce false;
            systemd-boot.enable = mkForce false;
          };

          # PS4 boots from multiboot initramfs into /sbin/init directly.
          boot.initrd.enable = mkDefault false;
          boot.initrd.includeDefaultModules = mkDefault false;

          icedos.system.bootloaders = {
            grub.enable = mkForce false;
            systemd-boot.enable = mkForce false;
          };

          # Root filesystem label from ps4-multiboot installer.
          # Drop host mounts and swap from the shared config, the PS4 has only this drive.
          fileSystems = mkForce {
            "/" = {
              device = "/dev/disk/by-label/ICEDOS-PS4";
              fsType = "ext4";
              options = [ "noatime" ];
            };
          };
          # Root is locked, so emergency mode would only hang the console.
          systemd.enableEmergencyMode = mkDefault false;

          # Kernel and graphics configuration.
          icedos.hardware.kernel.variant = mkForce "ps4";
          boot.kernelPackages = mkOverride 40 pkgs.linuxPackages_ps4;

          hardware.graphics = {
            package = pkgs.mesa-ps4;
            package32 = pkgs.pkgsi686Linux.mesa-ps4;
          };

          # Wi-Fi and Bluetooth firmware from the kernel extra_firmware tree.
          hardware.firmware = [ pkgs.ps4-firmware ];

          # Keep HDMI output active on PS4 Slim/Pro consoles.
          systemd.services.ps4-hdmi-keepalive = {
            description = "Keep the PS4 Slim/Pro HDMI bridge output on";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.ps4-hdmi-keepalive}/bin/ps4-hdmi-keepalive";
              Restart = "always";
              RestartSec = 5;
            };
          };

          # Force disable features Jaguar CPU or console boot cannot run.
          services.scx-loader.enable = mkForce false;
          hardware.cpu.intel.updateMicrocode = mkForce false;
          services.throttled.enable = mkForce false;

          networking.hostName = mkDefault "icedos-ps4";

          environment.systemPackages = [
            pkgs.ps4-bridge
            pkgs.ps4-hdmi-keepalive
          ];

          nixpkgs.overlays = [
            mesaOverlay
            ps4PackagesOverlay
          ];

          # Load nix store paths into database on first boot.
          systemd.services.register-nix-paths = {
            description = "Register Nix Store Paths";
            unitConfig = {
              DefaultDependencies = false;
              ConditionPathExists = "/nix-path-registration";
            };
            wantedBy = [ "sysinit.target" ];
            before = [
              "sysinit.target"
              "shutdown.target"
              "nix-daemon.socket"
              "nix-daemon.service"
            ];
            after = [ "local-fs.target" ];
            conflicts = [ "shutdown.target" ];
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              ${lib.getExe' config.nix.package.out "nix-store"} --load-db < /nix-path-registration
              rm /nix-path-registration
              ${lib.getExe' config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system
            '';
          };

          system.build.ps4RootfsTarball =
            let
              # busybox switch_root leaves /proc, /sys and /dev unmounted; stage 2 needs them.
              ps4Init = pkgs.writeScript "ps4-init" ''
                #!${pkgs.runtimeShell}
                m=${pkgs.util-linux}/bin/mount
                mountpoint() { ${pkgs.util-linux}/bin/mountpoint -q "$1"; }
                mountpoint /proc || $m -t proc proc /proc
                mountpoint /sys || $m -t sysfs sysfs /sys
                mountpoint /dev || $m -t devtmpfs devtmpfs /dev
                [ -e /dev/fd ] || ${pkgs.coreutils}/bin/ln -s /proc/self/fd /dev/fd
                exec ${config.system.build.toplevel}/init "$@"
              '';
            in
            pkgs.callPackage "${toString modulesPath}/../lib/make-system-tarball.nix"
              {
                fileName = "icedos-ps4-rootfs";
                extraArgs = "--owner=0";

                storeContents = [
                  {
                    object = config.system.build.toplevel;
                    symlink = "none";
                  }
                  {
                    object = ps4Init;
                    symlink = "none";
                  }
                ];

                contents = [
                  {
                    source = ps4Init;
                    target = "/sbin/init";
                  }
                  {
                    source = config.system.build.toplevel + "/etc/os-release";
                    target = "/etc/os-release";
                  }
                  {
                    source = pkgs.writeText "ps4-distro-name" "IceDOS\n";
                    target = "/etc/ps4-distro/name";
                  }
                ];

                extraCommands = ''
                  mkdir -p proc sys dev nix/var/nix/profiles usr/lib/firmware/amdgpu usr/lib/firmware/edid
                '';
              };

          system.build.ps4BootFiles = pkgs.runCommand "ps4-boot-files" { } ''
            mkdir -p $out
            cp ${config.boot.kernelPackages.kernel}/bzImage $out/bzImage
          '';

          icedos.system.tips.list = [
            "PS4 device profile active: HDMI keepalive, Liverpool/Gladius Mesa and dmem enabled."
          ];
        }
      )
    ];

  meta = {
    name = "ps4";
    dependencies = [
      {
        modules = [
          "graphics"
          "kernel"
          "ps4-kernel"
        ];
      }
    ];
  };
}
