{ icedosLib, ... }:

{
  options.icedos.hardware.devices.steamdeck.lcdOverclock = icedosLib.mkBoolOption {
    default = false;
  };

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
          cfg = config.icedos;
        in
        {
          jovian.devices.steamdeck = mkIf (!cfg.system.isFirstBuild) {
            enable = true;
            enableGyroDsuService = true;
            autoUpdate = true;
          };

          nixpkgs.overlays = mkIf (cfg.hardware.devices.steamdeck.lcdOverclock) [
            (final: super: {
              gamescope = super.gamescope.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [ ./patch.diff ];
              });
            })
          ];
        }
      )
    ];

  meta.name = "steamdeck";
}
