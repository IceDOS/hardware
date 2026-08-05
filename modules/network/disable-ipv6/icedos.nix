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
      }
    ];

  meta.name = "disable-ipv6";
}
