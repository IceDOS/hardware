{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kmscon.autologinUser =
    let
      inherit (icedosLib) mkStrOption;
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.kmscon) autologinUser;
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
          inherit (lib) mkIf mkForce;
        in
        {
          services.kmscon = {
            enable = true;
            autologinUser = mkIf (autologinUser != "") autologinUser;
            extraOptions = "--term xterm-256color";
            config.hwaccel = true;
          };

          # Drop kmsconvt@tty1 to prevent VT race with display managers
          # (upstream 54f2c962 unconditionally pulls kmscon into getty.target).
          systemd.services."kmsconvt@tty1".wantedBy = mkForce [ ];
        }
      )
    ];

  meta.name = "kmscon";
}
