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

          # Nixpkgs commit 54f2c962 ("nixos/kmscon: remove dependency on agetty",
          # merged 2026-04-22) added an unconditional
          # `systemd.services."kmsconvt@tty1".wantedBy = [ "getty.target" ];` to the
          # kmscon module. Every NixOS display manager that lands on tty1 (greetd
          # hardcoded, gdm/sddm by default, lightdm via minimum-vt=1) then races
          # kmscon for the VT; kmscon wins DRM master and the compositor fails
          # ("Failed to obtain file descriptor for drm device"). Drop the tty1
          # pull-in so kmscon stays on tty2..6 only (still reachable via the
          # autovt@.service alias upstream sets).
          systemd.services."kmsconvt@tty1".wantedBy = lib.mkForce [ ];
        }
      )
    ];

  meta.name = "kmscon";
}
