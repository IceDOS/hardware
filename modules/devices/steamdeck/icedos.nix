{ icedosLib, lib, ... }:

{
  options.icedos.hardware.devices.steamdeck.lcdOverclock =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.devices.steamdeck) lcdOverclock;
    in
    icedosLib.mkBoolOption { default = lcdOverclock; };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        let
          inherit (lib) mkIf;
          inherit (config) icedos;
          inherit (icedos) hardware system;
          inherit (system) isFirstBuild;
          inherit (hardware.devices.steamdeck) lcdOverclock;
        in
        {
          jovian.devices.steamdeck = mkIf (!isFirstBuild) {
            enable = true;
            enableGyroDsuService = true;
            autoUpdate = true;
          };

          nixpkgs.overlays = mkIf lcdOverclock [
            (final: super: {
              gamescope = super.gamescope.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [ ./patch.diff ];
              });
            })
          ];
        }
      )
    ];

  meta = {
    name = "steamdeck";

    dependencies = [
      {
        url = "github:icedos/providers";
        modules = [ "jovian" ];
      }
    ];
  };
}
