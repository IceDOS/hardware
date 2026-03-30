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
          inherit (config.icedos) hardware;
          inherit (hardware.kernel) variant swappiness;
          inherit (lib) hasAttr mkIf;

          kernelVariant = "linuxPackages_${variant}";
        in
        {
          boot = {
            kernel.sysctl."vm.swappiness" =
              if
                (
                  let
                    cfg = config.icedos;
                  in
                  hasAttr "tweaks" cfg && hasAttr "cachyos" cfg.tweaks && cfg.tweaks.cachyos.useCachyosZramProfile
                )
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
