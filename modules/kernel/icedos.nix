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
          inherit (config.icedos.hardware.kernel) variant swappiness;
          inherit (lib) hasAttr mkIf;

          kernelVariant = "linuxPackages_${variant}";
        in
        {
          boot = {
            kernelPackages = mkIf (hasAttr kernelVariant pkgs) pkgs.${kernelVariant};
            kernel.sysctl."vm.swappiness" = toString swappiness;
          };
        }
      )
    ];

  meta.name = "kernel";
}
