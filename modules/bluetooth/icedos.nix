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
          cfg = config.icedos;
        in
        {
          environment.systemPackages = mkIf (lib.hasAttr "hyprland" cfg.desktop) [ pkgs.blueberry ];
          hardware.bluetooth.enable = true;
        }
      )
    ];

  meta.name = "bluetooth";
}
