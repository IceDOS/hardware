{ icedosLib, lib, ... }:

{
  options.icedos.hardware.bootloaders.grub.device =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.bootloaders.grub) device;
    in
    icedosLib.mkStrOption { default = device; };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:
        let
          inherit (config) icedos;
          inherit (icedos) hardware system;
          inherit (hardware.bootloaders.grub) device;
          inherit (system) generations;
        in
        {
          boot = {
            loader = {
              grub = {
                inherit device;
                enable = true;
                useOSProber = true;
                enableCryptodisk = true;
                configurationLimit = generations;
              };

              timeout = 1;
            };

            initrd.secrets = {
              "/crypto_keyfile.bin" = null;
            };
          };
        }
      )
    ];

  meta.name = "grub";
}
