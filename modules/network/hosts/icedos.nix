{ icedosLib, ... }:

{
  options.icedos.hardware.network.hosts = icedosLib.mkLinesOption { default = ""; };

  outputs.nixosModules =
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
