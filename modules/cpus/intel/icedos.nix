{ icedosLib, ... }:

{
  options.icedos.hardware.cpus.intel = icedosLib.mkBoolOption { default = true; };

  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.cpu.intel.updateMicrocode = true;
        services.throttled.enable = true;

        icedos.system.tips.list = [
          "Intel microcode updates install with every rebuild, so your CPU keeps its latest fixes."
        ];
      }
    ];

  meta.name = "intel";
}
