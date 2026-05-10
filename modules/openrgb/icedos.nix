{ icedosLib, lib, ... }:

{
  options.icedos.hardware.openrgb =
    let
      inherit (icedosLib) mkStrOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.openrgb)
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
          pkgs,
          ...
        }:
        let
          inherit (config.icedos) hardware;
          inherit (hardware) openrgb;
          inherit (openrgb) color profile;

          resolved = icedosLib.generateAccent config;

          # Priority: explicit `color` override > resolver accent.
          accentHex = if color != "" then color else resolved.hexNoHash;

          # profile xor color: a named profile is loaded as-is (its saved
          # colors win); otherwise we apply our chosen accent uniformly.
          cmdArgs = if profile != "" then "--profile ${profile}" else "--color ${accentHex}";
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
