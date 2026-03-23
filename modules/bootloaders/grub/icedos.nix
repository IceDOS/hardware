{ icedosLib, lib, ... }:

{
  options.icedos.hardware.bootloaders.grub.device =
    let
      inherit
        (
          (fromTOML (lib.readFile ./config.toml)).icedos.hardware.bootloaders.grub
        )
        device
        ;
    in
    icedosLib.mkStrOption { default = device; };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:
        let
          cfg = config.icedos;
        in
        {
          boot = {
            loader = {
              grub = {
                enable = true;
                device = cfg.hardware.bootloaders.grub.device;
                useOSProber = true;
                enableCryptodisk = true;
                configurationLimit = cfg.system.generations;
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
