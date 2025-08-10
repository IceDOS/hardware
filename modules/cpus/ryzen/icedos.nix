{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        boot = {
          kernelParams = [
            "amd-pstate=active"
            "amd_pstate.shared_mem=1"
          ];

          kernelModules = [
            "amd-pstate"
            "msr"
          ];
        };

        hardware.cpu.amd.updateMicrocode = true;
      }
    ];

  meta.name = "ryzen";
}
