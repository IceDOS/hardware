{ ... }:

{
  inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

  outputs.nixosModules =
    { inputs, ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          inherit (config.icedos.hardware.kernel) variant;
          inherit (inputs) icedos-state nix-cachyos-kernel;
          inherit (lib) elem importJSON mkForce;
          inherit (nix-cachyos-kernel.overlays) pinned;
          inherit (pkgs) cachyosKernels linuxPackages;

          substituter = "https://attic.xuyh0120.win/lantian";
        in
        {
          boot.kernelPackages =
            if
              (elem substituter (
                if (icedos-state != null) then importJSON "${icedos-state}/substituters" else [ ]
              ))
            then
              mkForce cachyosKernels."linuxPackages-cachyos-${variant}"
            else
              linuxPackages;

          nixpkgs.overlays = [ pinned ];
          nix.settings.substituters = [ substituter ];
          nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
        }
      )
    ];

  meta.name = "cachyos-kernel";
}
