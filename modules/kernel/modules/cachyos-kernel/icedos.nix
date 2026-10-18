{
  config,
  lib,
  icedosLib,
  ...
}:

let
  cfg = config.hardware.kernel.cachyos or { };

  inherit (lib) importTOML;
  defaults = (importTOML ./config.toml).icedos.hardware.kernel.cachyos;

  inherit (defaults)
    applyWithoutSubstituter
    branch
    substituters
    ;
in
{
  options.icedos.hardware.kernel.cachyos =
    let
      inherit (icedosLib) mkBoolOption mkStrOption mkSubmoduleOption;
    in
    {
      applyWithoutSubstituter = mkBoolOption { default = applyWithoutSubstituter; };
      branch = mkStrOption { default = branch; };

      substituters = mkSubmoduleOption { default = { }; } {
        primary = mkBoolOption { default = substituters.primary; };
        secondary = mkBoolOption { default = substituters.secondary; };
      };
    };

  inputs.nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/${cfg.branch or branch}";

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
          inherit (icedos.hardware.kernel) cachyos variant;
          inherit (inputs) icedos-state nix-cachyos-kernel;

          inherit (lib)
            any
            attrValues
            catAttrs
            elem
            concatStringsSep
            filter
            filterAttrs
            importJSON
            mkForce
            mkIf
            optional
            ;

          inherit (nix-cachyos-kernel.overlays) pinned;
          inherit (pkgs) cachyosKernels linuxPackages;

          # Third-party caches, bootstrapped via /etc/icedos/substituters.
          # secondary is a community mirror the upstream author does not vouch for.
          caches = {
            primary = {
              url = "https://attic.xuyh0120.win/lantian";
              key = "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=";
            };

            secondary = {
              url = "https://cache.xinux.uz";
              key = "cache.xinux.uz:BXCrtqejFjWzWEB9YuGB7X2MV4ttBur1N8BkwQRdH+0=";
            };
          };

          enabledCaches = attrValues (filterAttrs (name: _: cachyos.substituters.${name}) caches);
          urls = catAttrs "url" enabledCaches;

          registered = if (icedos-state != null) then importJSON "${icedos-state}/substituters" else [ ];

          missingUrls = filter (url: !elem url registered) urls;
          shouldApplyCachyosKernel = any (url: elem url registered) urls || cachyos.applyWithoutSubstituter;
        in
        {
          warnings =
            optional (urls == [ ] && !cachyos.applyWithoutSubstituter) ''
              cachyos-kernel: every icedos.hardware.kernel.cachyos.substituters entry is false,
              so the cachyos kernel is never applied. Enable one, or set applyWithoutSubstituter = true.
            ''
            ++ optional (shouldApplyCachyosKernel && missingUrls != [ ]) ''
              cachyos-kernel: this build does not use these substituters yet:
                ${concatStringsSep "\n    " missingUrls}
              They are registered by this generation and picked up from
              /etc/icedos/substituters once it is activated. Run 'icedos rebuild' again
              after activation to fetch the kernel from them.
            ''
            ++ optional (urls != [ ] && !shouldApplyCachyosKernel) ''
              cachyos-kernel: the cachyos kernel is NOT applied in this generation.
              This build only registers the cachyos substituters (nix.settings.substituters);
              it is picked up from /etc/icedos/substituters only after the new generation
              is activated. To actually use the cachyos kernel:
                1. apply this generation: 'icedos rebuild' activates immediately;
                   'icedos rebuild --boot' needs a reboot to apply it (a bare --build
                   only builds — re-run 'icedos rebuild' without --build to activate);
                2. re-run 'icedos rebuild' — the registered substituter is now visible
                   and the cachyos kernel is applied;
                3. that generation also needs a switch/reboot to boot the new kernel.
              Set icedos.hardware.kernel.cachyos.applyWithoutSubstituter = true to skip
              the substituter bootstrap and apply the kernel from source next rebuild.
            '';

          boot.kernelPackages = mkForce (
            if shouldApplyCachyosKernel then
              cachyosKernels."linuxPackages-cachyos-${variant}"
            else
              linuxPackages
          );

          boot.zfs.package = mkIf (shouldApplyCachyosKernel && zfs) zfs_cachyos;
          nixpkgs.overlays = [ pinned ];
          nix.settings.substituters = urls;
          nix.settings.trusted-public-keys = catAttrs "key" enabledCaches;

          icedos.system.tips.list =
            optional (!shouldApplyCachyosKernel)
              "The CachyOS kernel needs two rebuilds: the first sets up its download server, the second installs it.";
        }
      )
    ];

  meta.name = "cachyos-kernel";
}
