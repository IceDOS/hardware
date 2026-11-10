{ icedosLib, ... }:

{
  options.icedos.hardware.cpus.ryzen = icedosLib.mkBoolOption { default = true; };

  outputs.nixosModules =
    { ... }:
    [
      {
        boot = {
          kernelParams = [
            # Only takes effect on CPUs with CPPC (Zen 2+).
            "amd-pstate=active"
          ];

          kernelModules = [ "msr" ];
        };

        hardware.cpu.amd.updateMicrocode = true;

        icedos.system.tips.list = [
          "On Zen 2 and newer, amd-pstate lets the CPU pick its own speed, saving power when idle."
        ];
      }
    ];

  meta.name = "ryzen";
}
