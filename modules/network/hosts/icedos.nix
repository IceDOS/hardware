{ icedosLib, lib, ... }:

{
  options.icedos.hardware.network.hosts =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.network) hosts;
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
