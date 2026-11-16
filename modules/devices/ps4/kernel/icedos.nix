{
  ...
}:

{
  inputs.ps4-linux = {
    url = "gitlab:rmuxnet/linux/62ff57d280e2fb21e4f22d75ff9ae711d6cf9da9";
    flake = false;
  };

  outputs.nixosModules =
    { inputs, ... }:
    [
      (
        let
          kernelSrc = inputs.ps4-linux;

          overlay = final: prev: {
            linux_ps4_src = kernelSrc;
            linux_ps4 = final.callPackage ./package.nix {
              src = kernelSrc;
            };
            linuxPackages_ps4 = final.linuxPackagesFor final.linux_ps4;
          };
        in
        {
          nixpkgs.overlays = [ overlay ];
        }
      )
    ];

  meta.name = "ps4-kernel";
}
