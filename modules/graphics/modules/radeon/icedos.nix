{ icedosLib, lib, ... }:

{
  options.icedos.hardware.graphics.radeon =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.graphics.radeon) featureMask lockupTimeout rocm;
    in
    {
      featureMask = mkStrOption { default = featureMask; };
      lockupTimeout = mkStrOption { default = lockupTimeout; };
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
          inherit (config.icedos.hardware.graphics.radeon) featureMask lockupTimeout rocm;
          inherit (lib) optional optionals;
        in
        {
          assertions = [
            {
              # amdgpu parses up to four comma-separated ms values: GFX,Compute,SDMA,Video.
              assertion = lockupTimeout == "" || builtins.match "-?[0-9]+(,-?[0-9]+){0,3}" lockupTimeout != null;
              message = ''
                icedos.hardware.graphics.radeon.lockupTimeout must be one to four
                comma-separated integers in ms (GFX,Compute,SDMA,Video), got "${lockupTimeout}".
              '';
            }
          ];

          boot = {
            initrd.kernelModules = [ "amdgpu" ];
            kernelParams =
              optional (featureMask != "") "amdgpu.ppfeaturemask=${featureMask}"
              ++ optional (lockupTimeout != "") "amdgpu.lockup_timeout=${lockupTimeout}";
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
