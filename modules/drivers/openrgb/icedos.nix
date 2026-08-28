{ icedosLib, lib, ... }:

{
  options.icedos.hardware.drivers.openrgb =
    let
      inherit (icedosLib) mkStrOption;
      inherit (lib) importTOML;

      inherit ((importTOML ./config.toml).icedos.hardware.drivers.openrgb)
        color
        profile
        ;
    in
    {
      color = mkStrOption { default = color; };
      profile = mkStrOption { default = profile; };
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
          inherit (config.icedos) hardware;
          inherit (hardware.drivers) openrgb;
          inherit (openrgb) color profile;

          resolved = icedosLib.generateAccent config;

          accentHex = if color != "" then color else resolved.hexNoHash;

          # profile xor color: a named profile is loaded as-is (its saved
          # colors win); otherwise we apply our chosen accent uniformly.
          cmdArgs =
            if profile != "" then
              "--profile ${lib.escapeShellArg profile}"
            else
              "--color ${lib.escapeShellArg accentHex}";
        in
        {
          assertions = [
            {
              assertion = color == "" || builtins.match "^[0-9A-Fa-f]{6}(,[0-9A-Fa-f]{6})*$" color != null;
              message = "icedos.hardware.drivers.openrgb.color: must be one or more comma-separated bare 6-digit hex values (e.g. \"FF0000\" or \"FF0000,00FF00\") when set.";
            }
          ];

          services.hardware.openrgb.enable = true;

          systemd.services.openrgb-profile-setter = {
            description = "OpenRGB profile setter";

            # Re-apply on resume — GPU LED state is lost during sleep and
            # openrgb doesn't self-restore. After=/WantedBy= targets both sides.
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
                # Wait for openrgb daemon (hardware detection races startup).
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
