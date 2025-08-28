{ icedosLib, ... }:

{
  options.icedos.hardware =
    let
      inherit (icedosLib) mkBoolOption;
    in
    {
      devices = {
        laptop = mkBoolOption { default = false; };
        server = mkBoolOption { default = false; };
      };

      network.firewall = mkBoolOption { default = true; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:
        {
          hardware.enableAllFirmware = true;
          networking.firewall.enable = config.icedos.hardware.network.firewall;
          networking.hostName = "icedos";
          services.fstrim.enable = true; # Enable SSD TRIM
          systemd.services.NetworkManager-wait-online.enable = false;
        }
      )
    ];

  meta.name = "default";
}
