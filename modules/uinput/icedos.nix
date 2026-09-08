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

          icedos.system.tips.list = [
            "Remapping apps can act as a virtual keyboard, mouse or controller."
          ];
        }
      )
    ];

  meta.name = "uinput";
}
