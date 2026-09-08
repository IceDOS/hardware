{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        boot.kernel.sysctl = {
          "net.ipv6.conf.all.disable_ipv6" = true;
          "net.ipv6.conf.default.disable_ipv6" = true;
        };

        icedos.system.tips.list = [
          "IPv6 is turned off, which fixes slow or failing connections on some networks."
        ];
      }
    ];

  meta.name = "disable-ipv6";
}
