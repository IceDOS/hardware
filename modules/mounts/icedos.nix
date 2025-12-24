{ icedosLib, ... }:

{
  options.icedos.hardware =
    let
      inherit (icedosLib) mkStrOption mkStrListOption mkSubmoduleListOption;
    in
    {
      mounts =

        mkSubmoduleListOption { default = [ ]; } {
          path = mkStrOption { };
          device = mkStrOption { };
          fsType = mkStrOption { };
          flags = mkStrListOption { };
        };

      swapDevices = mkStrListOption { default = [ ]; };
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

        let
          inherit (config.icedos.hardware) mounts swapDevices;
        in
        {
          fileSystems = lib.listToAttrs (
            map (mount: {
              name = mount.path;

              value = {
                device = mount.device;
                fsType = mount.fsType;
                options = mount.flags;
              };
            }) mounts
          );

          swapDevices = map (device: { inherit device; }) swapDevices;
        }
      )
    ];

  meta.name = "mounts";
}
