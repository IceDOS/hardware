{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.enableAllFirmware = true;
        networking.hostName = "icedos";
        services.fstrim.enable = true; # Enable SSD TRIM
        systemd.services.NetworkManager-wait-online.enable = false;
      }
    ];

  meta.name = "default";
}
