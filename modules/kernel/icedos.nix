{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kernel =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.kernel) swappiness variant;
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
          inherit (icedos) hardware tweaks;
          inherit (hardware.kernel) swappiness variant;

          kernelVariant = "linuxPackages_${variant}";
        in
        {
          boot = {
            kernel.sysctl."vm.swappiness" =
              if hasAttr "tweaks" icedos && hasAttr "cachyos" tweaks && tweaks.cachyos.useCachyosZramProfile then
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
