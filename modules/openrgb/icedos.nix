{ icedosLib, lib, ... }:

{
  options.icedos.hardware.openrgb.profile =
    let
      inherit (icedosLib) mkStrOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.openrgb) profile;
    in
    mkStrOption { default = profile; };

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
          inherit (lib) mapAttrs;
        in
        {
          home-manager.users = mapAttrs (user: _: {
            systemd.user.services.openrgb = {
              Unit = {
                After = [
                  "network.target"
                  "lm_sensors.service"
                ];

                Description = "OpenRGB profile setter";
              };

              Install.WantedBy = [ "multi-user.target" ];

              Service = {
                ExecStart = "${pkgs.writeShellScriptBin "openrgb-profile-setter" ''
                  ${pkgs.openrgb}/bin/openrgb --profile ${config.icedos.hardware.openrgb.profile}
                ''}/bin/openrgb-profile-setter";

                Restart = "always";
              };
            };
          }) config.icedos.users;

          services.hardware.openrgb.enable = true;
        }
      )
    ];

  meta.name = "openrgb";
}
