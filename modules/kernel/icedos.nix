{ icedosLib, ... }:

{
  options.icedos.hardware.kernel =
    let
      inherit (icedosLib) mkNumberOption mkStrOption;
    in
    {
      swappiness = mkNumberOption { default = 1; };
      version = mkStrOption { default = "lts"; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          pkgs,
          ...
        }:

        let
          cfg = config.icedos;
          kernel = cfg.hardware.kernel;

          chaoticKernel =
            kernel == "cachyos" || kernel == "cachyos-rc" || kernel == "cachyos-server" || kernel == "valve";
        in
        {
          boot = {
            kernelPackages =
              with pkgs;
              if (cfg.system.isFirstBuild && chaoticKernel) then
                linuxPackages
              else
                {
                  cachyos = linuxPackages_cachyos;
                  cachyos-server = linuxPackages_cachyos-server;
                  cachyos-rc = linuxPackages_cachyos-rc;
                  latest = linuxPackages_latest;
                  lts = linuxPackages;
                  valve = linuxPackages_jovian;
                  zen = linuxPackages_zen;
                }
                .${kernel.version};

            kernel.sysctl."vm.swappiness" = toString (kernel.swappiness);
          };
        }
      )
    ];

  meta = {
    name = "kernel";

    dependencies = [
      {
        url = "github:icedos/providers";
        modules = [ "chaotic" ];
      }
    ];
  };
}
