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
      }
    ];

  meta.name = "ryzen";
}
