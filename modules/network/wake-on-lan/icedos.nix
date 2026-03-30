{ icedosLib, lib, ... }:

{
  options.icedos.hardware.network.wakeOnLan.interfaces =
    let
      inherit (icedosLib) mkStrListOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.network.wakeOnLan) interfaces;
    in
    mkStrListOption { default = interfaces; };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          inherit (lib) genAttrs mkIf;
          inherit (config.icedos.hardware.network) firewall wakeOnLan;
          inherit (wakeOnLan) interfaces;
        in
        {
          environment.systemPackages = with pkgs; [
            wakeonlan
          ];

          networking = {
            interfaces = genAttrs interfaces (_: {
              wakeOnLan.enable = true;
            });

            firewall = mkIf firewall {
              allowedUDPPorts = [ 9 ];
            };
          };
        }
      )
    ];

  meta.name = "wake-on-lan";
}
