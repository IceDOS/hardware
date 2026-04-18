{ icedosLib, ... }:

{
  options.icedos.hardware.bluetooth = icedosLib.mkBoolOption { default = true; };

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
          inherit (builtins) any;
          inherit (lib) hasAttr mkIf;
          inherit (pkgs) blueman;
          inherit (config.icedos) desktop hardware;
        in
        {
          environment.systemPackages = mkIf (any (name: hasAttr name desktop) [
            "hyprland"
          ]) [ blueman ];

          hardware.bluetooth = {
            enable = true;

            settings = {
              General = {
                ControllerMode = "dual";
                Experimental = true;
                FastConnectable = (!hardware.devices.laptop);
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
