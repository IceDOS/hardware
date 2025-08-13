{ icedosLib, ... }:

{
  options.icedos.hardware.devices.steamdeck = icedosLib.mkBoolOption { default = true; };

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
        in
        {
          jovian.devices.steamdeck = mkIf (!config.icedos.system.isFirstBuild) {
            enable = true;
            enableGyroDsuService = true;
            autoUpdate = true;
          };
        }
      )
    ];

  meta.name = "steamdeck";
}
