{ icedosLib, lib, ... }:

{
  options.icedos.hardware.bluetooth =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.bluetooth) controllerMode justWorksRepairing;
    in
    {
      controllerMode =
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

      justWorksRepairing =
        icedosLib.mkEnumOption
          {
            path = "icedos.hardware.bluetooth.justWorksRepairing";
            source = ./config.toml;
            default = justWorksRepairing;
          }
          [
            "never"
            "confirm"
            "always"
          ];
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
                JustWorksRepairing = bluetooth.justWorksRepairing;
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
