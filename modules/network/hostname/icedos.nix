{ icedosLib, ... }:

{
  options.icedos.hardware.network.hostname = icedosLib.mkStrOption { default = "icedos"; };

  ouputs.nixosModules =
    { ... }:
    [
      (

        {
          config,
          ...
        }:

        {
          networking = {
            hostName = config.icedos.hardware.network.hostname;
          };
        }
      )
    ];

  meta.name = "hostname";
}
