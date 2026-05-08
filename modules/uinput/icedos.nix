{ icedosLib, ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:

        let
          inherit (config.icedos) users;
          inherit (icedosLib.users) mkGroupInjector;
        in
        {
          hardware.uinput.enable = true;

          users.users = mkGroupInjector "uinput" users;
        }
      )
    ];

  meta.name = "uinput";
}
