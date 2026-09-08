{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        services.upower.enable = true;

        icedos.system.tips.list = [
          "Your battery level and low-battery warnings come from upower."
        ];
      }
    ];

  meta.name = "upower";
}
