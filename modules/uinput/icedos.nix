{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.uinput.enable = true;
      }
    ];

  meta.name = "uinput";
}
