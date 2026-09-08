{ icedosLib, lib, ... }:

{
  options.icedos.hardware.zram.percentage =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.zram) percentage;
    in
    icedosLib.mkNumberOption { default = percentage; };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:
        {
          zramSwap = {
            enable = true;
            memoryPercent = config.icedos.hardware.zram.percentage;
          };

          icedos.system.tips.list = [
            "zram compresses memory instead of swapping to disk; size it with [icedos.hardware.zram] percentage."
          ];
        }
      )
    ];

  meta.name = "zram";
}
