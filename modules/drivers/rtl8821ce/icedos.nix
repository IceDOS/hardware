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

          icedos.system.tips.list = [
            "Your Realtek RTL8821CE Wi-Fi card uses the driver that keeps it stable."
          ];
        }
      )
    ];

  meta.name = "rtl8821ce";
}
