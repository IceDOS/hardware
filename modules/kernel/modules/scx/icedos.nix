{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kernel.scx =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.kernel.scx) extraArgs scheduler;
    in
    {
      extraArgs = icedosLib.mkStrListOption { default = extraArgs; };
      scheduler = icedosLib.mkStrOption { default = scheduler; };
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
          inherit (config.icedos.hardware.kernel) scx;
          inherit (scx) extraArgs scheduler;
        in
        {
          services.scx = {
            package = pkgs.scx.full;
            enable = true;
            scheduler = "scx_${scheduler}";
            inherit extraArgs;
          };

          icedos.system.tips.list = [
            "[icedos.hardware.kernel.scx] scheduler changes how apps share the CPU; lavd suits gaming."
          ];
        }
      )
    ];

  meta.name = "scx";
}
