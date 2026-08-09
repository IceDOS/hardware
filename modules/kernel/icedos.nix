{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kernel =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.kernel) swappiness variant;
      inherit (icedosLib) mkNumberOption mkStrOption;
    in
    {
      swappiness = mkNumberOption { default = swappiness; };
      variant = mkStrOption { default = variant; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          inherit (lib) hasAttr mkIf;
          inherit (config) icedos;
          inherit (icedos) hardware;
          inherit (hardware.kernel) swappiness variant;

          kernelVariant = "linuxPackages_${variant}";
        in
        {
          boot = {
            kernel.sysctl."vm.swappiness" =
              if
                icedosLib.hasModule {
                  inherit config;
                  url = "github:icedos/tweaks";
                  name = "cachyos";
                }
                && (icedos.tweaks.cachyos.useCachyosZramProfile or false)
              then
                "150"
              else
                toString swappiness;

            kernelPackages = mkIf (hasAttr kernelVariant pkgs) pkgs.${kernelVariant};
          };
        }
      )
    ];

  meta.name = "kernel";
}
