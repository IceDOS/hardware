{ icedosLib, ... }:

{
  options.icedos.hardware.cpus.ryzen = icedosLib.mkBoolOption { default = true; };

  outputs.nixosModules =
    { ... }:
    [
      {
        boot = {
          kernelParams = [
            "amd-pstate=active"
            "amd_pstate.shared_mem=1"
          ];

          kernelModules = [ "msr" ];
        };

        hardware.cpu.amd.updateMicrocode = true;

        icedos.system.tips.list = [
          "Your AMD CPU picks its own speed with amd-pstate, saving power when idle."
        ];
      }
    ];

  meta.name = "ryzen";
}
