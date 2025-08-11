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
            extraModulePackages = with config.boot.kernelPackages; [ rtl8821ce ];
            blacklistedKernelModules = [ "rtw88_8821ce" ];
            kernelModules = [ "rtl8821ce" ];
          };
        }
      )
    ];

  meta.name = "rtl8821ce";
}
