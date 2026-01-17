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
          inherit (pkgs) blueberry;
          inherit (config) icedos;
        in
        {
          environment.systemPackages = mkIf (any (name: hasAttr name icedos.desktop) [
            "cosmic"
            "hyprland"
          ]) [ blueberry ];

          hardware.bluetooth.enable = true;
        }
      )
    ];

  meta.name = "bluetooth";
}
