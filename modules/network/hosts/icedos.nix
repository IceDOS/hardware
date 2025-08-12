{ icedosLib, ... }:

{
  options.icedos.hardware.network.hosts = icedosLib.mkLinesOption { default = ""; };

  ouputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          ...
        }:

        {
          networking.extraHosts = config.icedos.hardware.network.hosts;
        }
      )
    ];

  meta.name = "hosts";
}
