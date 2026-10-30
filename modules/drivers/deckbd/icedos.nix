{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        {
          pkgs,
          ...
        }:

        let
          deckbd = "${pkgs.deckbd}/bin/deckbd";

          waitForController = pkgs.writeShellScript "deckbd-wait" ''
            DECKBD_RETRIES=10
            while true; do
              ${deckbd} query && exit 0
              if [ "$DECKBD_RETRIES" -eq "0" ]; then exit 1; fi
              sleep 1

              if [ "$DECKBD_RETRIES" -eq "1" ]; then
                echo -en "\rwaiting for deck controller to appear, $DECKBD_RETRIES retry remaining...  "
              else
                echo -en "\rwaiting for deck controller to appear, $DECKBD_RETRIES retries remaining..."
              fi
              DECKBD_RETRIES=$((DECKBD_RETRIES - 1))
            done
          '';
        in
        {
          boot.initrd = {
            kernelModules = [
              "uinput"
              "evdev"
              "hid_steam"
            ];

            systemd = {
              storePaths = [
                deckbd
                waitForController
              ];

              # Must be typing before systemd-cryptsetup asks for the LUKS passphrase.
              services.deckbd = {
                description = "Steam Deck controller as keyboard";
                wantedBy = [ "initrd.target" ];
                wants = [ "cryptsetup-pre.target" ];
                before = [
                  "cryptsetup-pre.target"
                  "initrd-switch-root.target"
                ];
                after = [
                  "systemd-modules-load.service"
                  "systemd-udev-trigger.service"
                ];
                conflicts = [ "initrd-switch-root.target" ];
                unitConfig.DefaultDependencies = false;

                serviceConfig = {
                  ExecStartPre = waitForController;
                  ExecStart = deckbd;
                  StandardOutput = "journal+console";
                };
              };
            };
          };

          nixpkgs.overlays = [
            (final: super: {
              deckbd = final.callPackage ./package.nix { };
            })
          ];

          icedos.system.tips.list = [
            "Your Steam Deck buttons work at the boot screen, so you can unlock the disk without a keyboard."
          ];
        }
      )
    ];

  meta.name = "deckbd";
}
