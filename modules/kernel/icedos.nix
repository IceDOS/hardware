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
        in
        {
          boot = {
            kernelPackages =
              with pkgs;
              {
                latest = linuxPackages_latest;
                lts = linuxPackages;
                zen = linuxPackages_zen;
              }
              .${kernel.version};

            kernel.sysctl."vm.swappiness" = toString (kernel.swappiness);
          };
        }
      )
    ];

  meta.name = "kernel";
}
