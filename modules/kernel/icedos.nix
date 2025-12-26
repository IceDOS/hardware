{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kernel =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.kernel) swappiness version;
      inherit (icedosLib) mkNumberOption mkStrOption;
    in
    {
      swappiness = mkNumberOption { default = swappiness; };
      version = mkStrOption { default = version; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          inherit (config.icedos.hardware.kernel) version swappiness;
          inherit (lib) mkIf;
        in
        {
          boot = {
            kernelPackages =
              with pkgs;
              mkIf (version != "")
                {
                  latest = linuxPackages_latest;
                  lts = linuxPackages;
                  zen = linuxPackages_zen;
                }
                .${version};

            kernel.sysctl."vm.swappiness" = toString swappiness;
          };
        }
      )
    ];

  meta.name = "kernel";
}
