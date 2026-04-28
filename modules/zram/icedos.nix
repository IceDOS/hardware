{ icedosLib, lib, ... }:

{
  options.icedos.hardware.zram.percentage =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.zram) percentage;
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
        }
      )
    ];

  meta.name = "zram";
}
