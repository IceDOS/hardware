{ icedosLib, lib, ... }:

{
  options.icedos.hardware.kernel.scx =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.kernel.scx) extraArgs scheduler;
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
        }
      )
    ];

  meta.name = "scx";
}
