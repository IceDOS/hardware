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

          icedos.system.tips.list = [
            "Block or redirect websites by adding lines to [icedos.hardware.network] hosts."
          ];
        }
      )
    ];

  meta.name = "hosts";
}
