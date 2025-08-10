{ icedosLib, ... }:

{
  options.icedos.hardware.cpus.intel = icedosLib.mkBoolOption { default = true; };

  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.cpu.intel.updateMicrocode = true;
        services.throttled.enable = true;
      }
    ];

  meta.name = "intel";
}
