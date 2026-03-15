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
          inherit (config) boot icedos;
          inherit (boot) kernelPackages supportedFilesystems;
          inherit (kernelPackages) zfs_cachyos;
          inherit (supportedFilesystems) zfs;
          inherit (icedos.hardware.kernel) variant;
          inherit (inputs) icedos-state nix-cachyos-kernel;

          inherit (lib)
            elem
            importJSON
            mkForce
            mkIf
            ;

          inherit (nix-cachyos-kernel.overlays) default;
          inherit (pkgs) cachyosKernels linuxPackages;

          substituter = "https://attic.xuyh0120.win/lantian";

          hasSubstituter = elem substituter (
            if (icedos-state != null) then importJSON "${icedos-state}/substituters" else [ ]
          );
        in
        {
          boot.kernelPackages =
            if hasSubstituter then mkForce cachyosKernels."linuxPackages-cachyos-${variant}" else linuxPackages;

          boot.zfs.package = mkIf (hasSubstituter && zfs) zfs_cachyos;
          nixpkgs.overlays = [ default ];
          nix.settings.substituters = [ substituter ];
          nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
        }
      )
    ];

  meta.name = "cachyos-kernel";
}
