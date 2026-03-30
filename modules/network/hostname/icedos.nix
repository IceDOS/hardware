{ icedosLib, lib, ... }:

{
  options.icedos.hardware.network.hostname =
    let
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.network) hostname;
    in
    icedosLib.mkStrOption { default = hostname; };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          ...
        }:

        {
          networking.hostName = config.icedos.hardware.network.hostname;
        }
      )
    ];

  meta.name = "hostname";
}
