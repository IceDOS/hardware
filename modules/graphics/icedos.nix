{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };
      }
    ];

  meta.name = "graphics";
}
