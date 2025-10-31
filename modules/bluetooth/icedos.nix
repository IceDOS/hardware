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
          inherit (lib) mkIf;
          inherit (pkgs) blueberry;
          inherit (config) icedos;
        in
        {
          environment.systemPackages = mkIf (lib.hasAttr "hyprland" icedos.desktop or false) [ blueberry ];
          hardware.bluetooth.enable = true;
        }
      )
    ];

  meta.name = "bluetooth";
}
