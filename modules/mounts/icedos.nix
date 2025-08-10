{ icedosLib, ... }:

{
  options.icedos.hardware.mounts =
    let
      inherit (icedosLib) mkStrOption mkStrListOption mkSubmoduleListOption;
    in
    mkSubmoduleListOption { default = [ ]; } {
      path = mkStrOption { };
      device = mkStrOption { };
      fsType = mkStrOption { };
      flags = mkStrListOption { };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        {
          fileSystems = lib.listToAttrs (
            map (mount: {
              name = mount.path;

              value = {
                device = mount.device;
                fsType = mount.fsType;
                options = mount.flags;
              };
            }) config.icedos.hardware.mounts
          );
        }
      )
    ];

  meta.name = "mounts";
}
