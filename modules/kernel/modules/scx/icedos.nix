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
          services.scx-loader = {
            enable = true;
            schedsPackages = [ pkgs.scx.full ];

            config = {
              default_sched = "scx_${scheduler}";
              default_mode = "Auto";
              # Empty keeps scx_loader's built-in flags for the mode.
              scheds."scx_${scheduler}" = lib.optionalAttrs (extraArgs != [ ]) { auto_mode = extraArgs; };
            };
          };

          icedos.system.tips.list = [
            "[icedos.hardware.kernel.scx] scheduler changes how apps share the CPU; lavd suits gaming."
          ];
        }
      )
    ];

  meta.name = "scx";
}
