{ icedosLib, lib, ... }:
{
  options.icedos.hardware.graphics.nvidia =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.graphics.nvidia)
        beta
        cuda
        openDrivers
        powerLimit
        ;
    in
    {
      beta = mkBoolOption { default = beta; };
      cuda = mkBoolOption { default = cuda; };
      openDrivers = mkBoolOption { default = openDrivers; };

      powerLimit =
        let
          inherit (powerLimit) enable value;
        in
        {
          enable = mkBoolOption { default = enable; };
          value = mkNumberOption { default = value; };
        };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        let
          inherit (lib) mkIf;
          inherit (config.icedos) hardware;
          inherit (hardware) graphics;
          inherit (graphics) nvidia;
          inherit (nvidia) powerLimit;
          nvidia_x11 = config.boot.kernelPackages.nvidia_x11.bin;
        in
        {
          services.xserver.videoDrivers = [ "nvidia" ]; # Install the nvidia drivers

          hardware.nvidia = {
            modesetting.enable = true;
            open = nvidia.openDrivers;

            package =
              if nvidia.beta then
                config.boot.kernelPackages.nvidiaPackages.beta
              else
                config.boot.kernelPackages.nvidiaPackages.stable;

            prime = mkIf hardware.devices.laptop {
              offload.enable = true;
              intelBusId = "PCI:0:2:0";
              nvidiaBusId = "PCI:1:0:0";
            };
          };

          # Enable nvidia gpu acceleration for containers
          hardware.nvidia-container-toolkit.enable =
            config.virtualisation.docker.enable || config.virtualisation.podman.enable;

          icedos.system.toolset.commands = mkIf hardware.devices.laptop [
            {
              command = "force-nvidia";

              script = ''
                export __NV_PRIME_RENDER_OFFLOAD=1
                export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
                export __GLX_VENDOR_LIBRARY_NAME=nvidia
                export __VK_LAYER_NV_optimus=NVIDIA_only
                exec "$@"
              '';

              help = "forces command to use nvidia gpu";
            }
          ];

          nixpkgs.config.cudaSupport = nvidia.cuda;

          # Set nvidia gpu power limit
          systemd.services.nv-power-limit = mkIf powerLimit.enable {
            enable = true;
            description = "Nvidia power limit control";
            after = [
              "syslog.target"
              "systemd-modules-load.service"
            ];

            unitConfig = {
              ConditionPathExists = "${nvidia_x11}/bin/nvidia-smi";
            };

            serviceConfig = {
              User = "root";
              ExecStart = "${nvidia_x11}/bin/nvidia-smi --power-limit=${toString powerLimit.value}";
            };

            wantedBy = [ "multi-user.target" ];
          };
        }
      )
    ];

  meta = {
    name = "nvidia";

    dependencies = [
      {
        modules = [ "graphics" ];
      }
    ];
  };
}
