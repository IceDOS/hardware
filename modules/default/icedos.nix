{ icedosLib, ... }:

{
  options.icedos.hardware.devices =
    let
      inherit (icedosLib) mkBoolOption;
    in
    {
      laptop = mkBoolOption { default = false; };
      server = mkBoolOption { default = false; };
    };

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
