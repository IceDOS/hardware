{ icedosLib, lib, ... }:

{
  options.icedos.hardware.bluetooth.controllerMode =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.bluetooth) controllerMode;
    in
    icedosLib.mkEnumOption
      {
        path = "icedos.hardware.bluetooth.controllerMode";
        source = ./config.toml;
        default = controllerMode;
      }
      [
        "bredr"
        "dual"
      ];

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
          inherit (builtins) any readFile;
          inherit (lib) hasAttr optionals;
          inherit (pkgs) blueman writeShellApplication;
          inherit (config.icedos) desktop hardware;
          inherit (hardware) bluetooth devices;

          bt-pair = writeShellApplication {
            name = "xbox-controller-pair";

            runtimeInputs = with pkgs; [
              bluez
              coreutils
              gnugrep
            ];

            text = readFile ./xbox-controller-pair.sh;
          };
        in
        {
          environment.systemPackages = [
            bt-pair
          ]
          ++ optionals (any (name: hasAttr name desktop) [ "hyprland" ]) [ blueman ];

          hardware.bluetooth = {
            enable = true;

            settings = {
              General = {
                ControllerMode = bluetooth.controllerMode;
                Experimental = true;
                FastConnectable = (!devices.laptop);
                JustWorksRepairing = "always";
                Privacy = "device";
              };

              LE = {
                MinConnectionInterval = 7;
                MaxConnectionInterval = 9;
                ConnectionLatency = 0;
              };
            };
          };
        }
      )
    ];

  meta.name = "bluetooth";
}
