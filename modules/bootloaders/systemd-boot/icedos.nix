{ icedosLib, lib, ... }:

{
  options.icedos.hardware.bootloaders.systemd-boot.mountPoint =
    let
      inherit ((fromTOML (lib.readFile ./config.toml)).icedos.hardware.bootloaders.systemd-boot)
        mountPoint
        ;
    in
    icedosLib.mkStrOption { default = mountPoint; };

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
              configurationLimit = cfg.system.generations;
              consoleMode = "max";
            };

            timeout = 1;
          };
        }
      )
    ];

  meta.name = "systemd-boot";
}
