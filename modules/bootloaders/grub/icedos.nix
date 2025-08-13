{ icedosLib, ... }:

{
  options.icedos.hardware.bootloaders.grub.device = icedosLib.mkStrOption { default = ""; };

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
