{ icedosLib, ... }:
{
  options.icedos.hardware.graphics.radeon.rocm = icedosLib.mkBoolOption { default = true; };

  outputs.nixosModules =
    { ... }:
    [
      (

        {
          config,
          ...
        }:

        let
          hardware = config.icedos.hardware;
        in
        {
          boot = {
            initrd.kernelModules = [ "amdgpu" ];
            kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
          };

          nixpkgs.config.rocmSupport = hardware.graphics.radeon.rocm;
        }
      )
    ];

  meta = {
    name = "radeon";
    depends = [ "graphics" ]; # TODO implement dependencies
  };
}
