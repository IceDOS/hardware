{ icedosLib, lib, ... }:

{
  options.icedos.hardware.openrgb =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.openrgb)
        color
        profile
        stylix
        ;
    in
    {
      color = mkStrOption { default = color; };
      profile = mkStrOption { default = profile; };
      stylix = mkBoolOption { default = stylix; };
    };

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
          inherit (icedosLib) generateAccentColor;
          inherit (lib) hasAttr;

          cfg = config.icedos.hardware.openrgb;
          desktop = config.icedos.desktop;

          stylixOn = (config.stylix.enable or false) && cfg.stylix;
          stylixColors = config.lib.stylix.colors or { };
          stylixAccentSlot = desktop.stylix.accentBase16Slot or "base0D";
          stylixAccentHex = stylixColors.${stylixAccentSlot} or null;

          # Desktop fallback: GNOME accent if gnome is enabled, otherwise the
          # icedos.desktop.accentColor TOML value. `generateAccentColor` returns
          # a `#XXXXXX` string; openrgb's --color wants bare hex digits, so we
          # strip the leading `#` (same idiom as cosmic/.../appearance/icedos.nix).
          desktopAccentHex =
            let
              raw = generateAccentColor {
                inherit (desktop) accentColor;
                gnomeAccentColor = desktop.gnome.accentColor or "blue";
                hasGnome = hasAttr "gnome" desktop;
              };
            in
            builtins.substring 1 (builtins.stringLength raw - 1) raw;

          # Priority: explicit `cfg.color` override > stylix accent > desktop fallback.
          accentHex =
            if cfg.color != "" then
              cfg.color
            else if (stylixOn && stylixAccentHex != null) then
              stylixAccentHex
            else
              desktopAccentHex;

          # profile xor color: a named profile is loaded as-is (its saved
          # colors win); otherwise we apply our chosen accent uniformly.
          cmdArgs = if cfg.profile != "" then "--profile ${cfg.profile}" else "--color ${accentHex}";
        in
        {
          services.hardware.openrgb.enable = true;

          systemd.services.openrgb-profile-setter = {
            description = "OpenRGB profile setter";

            # Run at boot AND after every resume — the GPU LED state is lost
            # during suspend/hibernate/hybrid-sleep, and openrgb's daemon
            # itself doesn't re-apply on resume. Each `*.target` activates at
            # the start of the corresponding transition; pairing `After=`
            # with `WantedBy=` lands the service on the resume side rather
            # than running before the system actually goes to sleep.
            wantedBy = [
              "multi-user.target"
              "suspend.target"
              "hibernate.target"
              "hybrid-sleep.target"
            ];

            after = [
              "openrgb.service"
              "suspend.target"
              "hibernate.target"
              "hybrid-sleep.target"
            ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.writeShellScript "openrgb-profile-setter" ''
                # Wait for the system openrgb daemon to be ready (hardware
                # detection races our startup, especially after resume).
                # Retry up to ~30s.
                for _ in $(seq 1 30); do
                  ${pkgs.openrgb}/bin/openrgb --list-devices >/dev/null 2>&1 && break
                  sleep 1
                done

                ${pkgs.openrgb}/bin/openrgb ${cmdArgs}
              ''}";
            };
          };
        }
      )
    ];

  meta.name = "openrgb";
}
