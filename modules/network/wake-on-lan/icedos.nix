{ icedosLib, lib, ... }:

{
  options.icedos.hardware.network.wake-on-lan.interfaces =
    let
      inherit (icedosLib) mkStrListOption;
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.network.wake-on-lan) interfaces;
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
          inherit (config.icedos.hardware.network) firewall wake-on-lan;
          inherit (wake-on-lan) interfaces;
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

          icedos.system.tips.list = [
            "Turn this machine on from another device with wakeonlan <mac address>."
          ];
        }
      )
    ];

  meta.name = "wake-on-lan";
}
