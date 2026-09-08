{ icedosLib, lib, ... }:

{
  options.icedos.hardware =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) importTOML;

      inherit ((importTOML ./config.toml).icedos.hardware)
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
        { config, lib, ... }:

        let
          inherit (lib) optionals;
          inherit (config.icedos.hardware.network) firewall;
        in
        {
          hardware.enableAllFirmware = true;
          networking.firewall.enable = firewall;
          services.fstrim.enable = true;
          systemd.services.NetworkManager-wait-online.enable = false;

          icedos.system.tips.list = [
            "Your SSD is trimmed on a timer, so it keeps its speed over the years."
          ]
          ++ optionals firewall [
            "Set [icedos.hardware.network] firewall = false in config.toml if it blocks something you need."
          ];
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
          "network-manager"
        ];
      }
    ];
  };
}
