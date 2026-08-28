{ lib, icedosLib, ... }:

{
  options.icedos.hardware.kernel.cachyos.applyWithoutSubstituter =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) importTOML;

      inherit ((importTOML ./config.toml).icedos.hardware.kernel.cachyos)
        applyWithoutSubstituter
        ;
    in
    mkBoolOption { default = applyWithoutSubstituter; };

  inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

  outputs.nixosModules =
    { inputs, ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          inherit (config) boot icedos;
          inherit (boot) kernelPackages supportedFilesystems;
          inherit (kernelPackages) zfs_cachyos;
          inherit (supportedFilesystems) zfs;
          inherit (icedos.hardware.kernel) cachyos variant;
          inherit (inputs) icedos-state nix-cachyos-kernel;

          inherit (lib)
            elem
            importJSON
            mkForce
            mkIf
            optional
            ;

          inherit (nix-cachyos-kernel.overlays) default;
          inherit (pkgs) cachyosKernels linuxPackages;

          # Third-party cache (attic.xuyh0120.win). Bootstrapped via
          # /etc/icedos/substituters; trusted key added when kernel applies.
          substituter = "https://attic.xuyh0120.win/lantian";

          shouldApplyCachyosKernel =
            elem substituter (if (icedos-state != null) then importJSON "${icedos-state}/substituters" else [ ])
            || cachyos.applyWithoutSubstituter;
        in
        {
          warnings = optional (!shouldApplyCachyosKernel) ''
            cachyos-kernel: the cachyos kernel is NOT applied in this generation.
            This build only registers the lantian substituter (nix.settings.substituters);
            it is picked up from /etc/icedos/substituters only after the new generation
            is activated. To actually use the cachyos kernel:
              1. apply this generation: 'icedos rebuild' activates immediately;
                 'icedos rebuild --boot' needs a reboot to apply it (a bare --build
                 only builds — re-run 'icedos rebuild' without --build to activate);
              2. re-run 'icedos rebuild' — the registered substituter is now visible
                 and the cachyos kernel is applied;
              3. that generation also needs a switch/reboot to boot the new kernel.
            Set icedos.hardware.kernel.cachyos.applyWithoutSubstituter = true to skip
            the substituter bootstrap and apply the kernel from source next rebuild.
          '';

          boot.kernelPackages = mkForce (
            if shouldApplyCachyosKernel then
              cachyosKernels."linuxPackages-cachyos-${variant}"
            else
              linuxPackages
          );

          boot.zfs.package = mkIf (shouldApplyCachyosKernel && zfs) zfs_cachyos;
          nixpkgs.overlays = [ default ];
          nix.settings.substituters = [ substituter ];

          nix.settings.trusted-public-keys = [
            "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
          ];
        }
      )
    ];

  meta.name = "cachyos-kernel";
}
