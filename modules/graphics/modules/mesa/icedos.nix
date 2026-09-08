{ icedosLib, lib, ... }:

{
  options.icedos.hardware.graphics.mesa =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.graphics.mesa) rc git;
    in
    {
      rc = mkBoolOption {
        default = rc;
        description = "Build mesa from the release-candidate snapshot pinned in rc.json (vendors venus-protocol in-tree, so the virtio Vulkan driver is kept).";
      };
      git = mkBoolOption {
        default = git;
        description = "Build mesa from the git snapshot pinned in git.json. Until nixpkgs wires venus-protocol into mesa, the virtio (venus) Vulkan driver is disabled in this build — relevant if you need Vulkan in a virtio-gpu VM guest.";
      };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        let
          inherit (lib) mkIf optionals;
          inherit (config.icedos.hardware.graphics.mesa) rc git;
        in
        {
          assertions = [
            {
              assertion = !(rc && git);
              message = "icedos.hardware.graphics.mesa: only one of `rc` and `git` can be enabled at a time.";
            }
          ];

          nixpkgs.overlays = lib.mkMerge [
            (mkIf rc (import ./rc.nix).nixpkgs.overlays)
            (mkIf git (import ./git.nix).nixpkgs.overlays)
          ];

          icedos.system.tips.list = optionals (!rc && !git) [
            "[icedos.hardware.graphics.mesa] rc = true tries the next graphics driver shortly before its release."
            "[icedos.hardware.graphics.mesa] git = true runs the newest in-development graphics driver, bugs included."
          ];
        }
      )
    ];

  meta.name = "mesa";
}
