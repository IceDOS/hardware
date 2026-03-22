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
            "cosmic"
            "hyprland"
          ]) [ blueman ];

          hardware.bluetooth = {
            enable = true;

            settings = {
              General = {
                ControllerMode = "bredr";
                Experimental = true;
                FastConnectable = (!hardware.devices.laptop);
              };
            };
          };
        }
      )
    ];

  meta.name = "bluetooth";
}
