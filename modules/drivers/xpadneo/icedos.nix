{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.xpadneo.enable = true;
      }
    ];

  meta.name = "xpadneo";
}
