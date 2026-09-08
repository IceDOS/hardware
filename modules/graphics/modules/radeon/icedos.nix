{ icedosLib, lib, ... }:

{
  options.icedos.hardware.graphics.radeon =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.graphics.radeon) featureMask rocm;
    in
    {
      featureMask = mkStrOption { default = featureMask; };
      rocm = mkBoolOption { default = rocm; };
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
          inherit (config.icedos.hardware.graphics.radeon) featureMask rocm;
          inherit (lib) mkIf optionals;
        in
        {
          boot = {
            initrd.kernelModules = [ "amdgpu" ];
            kernelParams = mkIf (featureMask != "") [ "amdgpu.ppfeaturemask=${featureMask}" ];
          };

          nixpkgs.config.rocmSupport = rocm;

          icedos.system.tips.list = optionals (!rocm) [
            "[icedos.hardware.graphics.radeon] rocm = true adds AMD support for AI and compute apps."
          ];
        }
      )
    ];

  meta = {
    name = "radeon";

    dependencies = [
      {
        modules = [ "graphics" ];
      }
    ];
  };
}
