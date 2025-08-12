{ icedosLib, ... }:

{
  options.icedos.hardware.zram.percentage = icedosLib.mkNumberOption { default = 10; };

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
