{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { config, lib, ... }:

        let
          inherit (config.icedos) users;
          inherit (lib) mapAttrs;
        in
        {
          hardware.uinput.enable = true;

          users.users = mapAttrs (_: _: { extraGroups = [ "uinput" ]; }) users;
        }
      )
    ];

  meta.name = "uinput";
}
