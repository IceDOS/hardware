{ icedosLib, ... }:

{
  options.icedos.hardware.network.hostname =
    let
      defaultConfig =
        let
          inherit (builtins) readFile;
        in
        (fromTOML (readFile ./config.toml)).icedos.hardware.network;
    in
    icedosLib.mkStrOption { default = defaultConfig.hostname; };

  ouputs.nixosModules =
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
