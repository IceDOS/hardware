{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        services.upower.enable = true;
      }
    ];

  meta.name = "upower";
}
