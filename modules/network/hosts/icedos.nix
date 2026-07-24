{ icedosLib, lib, ... }:

{
  options.icedos.hardware.network.hosts =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.network) hosts;
    in
    icedosLib.mkLinesOption { default = hosts; };

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
