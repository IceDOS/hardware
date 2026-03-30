{ icedosLib, lib, ... }:

{
  options.icedos.hardware =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware)
        devices
        network
        ;

      inherit (devices) laptop server;
      inherit (network) firewall;
    in
    {
      devices = {
        laptop = mkBoolOption { default = laptop; };
        server = mkBoolOption { default = server; };
      };

      network.firewall = mkBoolOption { default = firewall; };
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
