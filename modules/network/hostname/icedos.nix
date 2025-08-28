{ icedosLib, ... }:

{
  options.icedos.hardware.network.hostname = icedosLib.mkStrOption { default = "icedos"; };

  ouputs.nixosModules =
    { ... }:
    [
      (

        {
          config,
          lib,
          ...
        }:

        {
          networking.hostName = lib.mkForce config.icedos.hardware.network.hostname;
        }
      )
    ];

  meta.name = "hostname";
}
