{ icedosLib, ... }:

{
  options.icedos.hardware.bootloaders.systemd-boot.mountPoint = icedosLib.mkStrOption {
    default = "";
  };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          ...
        }:

        let
          cfg = config.icedos;
        in
        {
          boot.loader = {
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = cfg.hardware.bootloaders.systemd-boot.mountPoint;
            };

            systemd-boot = {
              enable = true;
              configurationLimit = cfg.system.generations.bootEntries;
              consoleMode = "max";
            };

            timeout = 1;
          };
        }
      )
    ];

  meta.name = "systemd-boot";
}
