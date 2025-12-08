{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kmscon.autologinUser =
    let
      inherit (icedosLib) mkStrOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.kmscon) autologinUser;
    in
    mkStrOption { default = autologinUser; };

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
          inherit (config.icedos.hardware.kmscon) autologinUser;
          inherit (lib) mkIf;
        in
        {
          services.kmscon = {
            enable = true;
            autologinUser = mkIf (autologinUser != "") autologinUser;
            extraOptions = "--term xterm-256color";
            hwRender = true;
          };
        }
      )
    ];

  meta.name = "kmscon";
}
