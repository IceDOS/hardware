{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          ...
        }:

        {
          boot = {
            kernelModules = [ "zenergy" ];
            extraModulePackages = with config.boot.kernelPackages; [ zenergy ];
          };

          icedos.system.tips.list = [
            "System monitors can show how much power your Ryzen CPU is drawing."
          ];
        }
      )
    ];

  meta.name = "zenergy";
}
