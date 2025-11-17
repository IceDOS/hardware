{ icedosLib, lib, ... }:

{
  options.icedos.hardware.graphics.radeon =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.graphics.radeon) featureMask rocm;
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
          inherit (lib) mkIf;
        in
        {
          boot = {
            initrd.kernelModules = [ "amdgpu" ];
            kernelParams = mkIf (featureMask != "") [ "amdgpu.ppfeaturemask=${featureMask}" ];
          };

          nixpkgs.config.rocmSupport = rocm;
        }
      )
    ];

  meta.name = "radeon";
}
