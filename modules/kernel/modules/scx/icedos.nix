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
          inherit (scx) scheduler;

          extraArgs =
            if ((builtins.length scx.extraArgs) == 0) && scheduler == "lavd" then
              [ "--autopower" ]
            else
              scx.extraArgs;
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
