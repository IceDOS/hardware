{ icedosLib, lib, ... }:

{
  options.icedos.hardware.bootloaders.systemd-boot.mountPoint =
    let
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.bootloaders.systemd-boot)
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
          inherit (config) icedos;
          inherit (icedos) hardware system;
          inherit (hardware.bootloaders.systemd-boot) mountPoint;
          inherit (system) generations;
        in
        {
          boot.loader = {
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = mountPoint;
            };

            systemd-boot = {
              enable = true;
              configurationLimit = generations;
              consoleMode = "max";
            };

            timeout = 1;
          };
        }
      )
    ];

  meta.name = "systemd-boot";
}
