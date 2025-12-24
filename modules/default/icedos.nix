{ icedosLib, ... }:

{
  options.icedos.hardware =
    let
      inherit (icedosLib) mkBoolOption;

      defaultConfig =
        let
          inherit (builtins) readFile;
        in
        (fromTOML (readFile ./config.toml)).icedos.hardware;
    in
    {
      devices = {
        laptop = mkBoolOption { default = defaultConfig.devices.laptop; };
        server = mkBoolOption { default = defaultConfig.devices.server; };
      };

      network.firewall = mkBoolOption { default = defaultConfig.network.firewall; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:
        {
          hardware.enableAllFirmware = true;
          networking.firewall.enable = config.icedos.hardware.network.firewall;
          services.fstrim.enable = true; # Enable SSD TRIM
          systemd.services.NetworkManager-wait-online.enable = false;
        }
      )
    ];

  meta = {
    name = "default";

    dependencies = [
      {
        modules = [
          "hostname"
          "kmscon"
          "mounts"
        ];
      }
    ];
  };
}
