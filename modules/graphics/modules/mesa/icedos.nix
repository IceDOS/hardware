{ icedosLib, lib, ... }:

{
  options.icedos.hardware.graphics.mesa =
    let
      inherit (icedosLib) mkBoolOption mkStrOption;
      inherit (lib) importTOML;

      inherit ((importTOML ./config.toml).icedos.hardware.graphics.mesa)
        rc
        git
        shaderCacheMaxSize
        ;
    in
    {
      rc = mkBoolOption {
        default = rc;
        description = "Build mesa from the release-candidate snapshot pinned in rc.json.";
      };
      git = mkBoolOption {
        default = git;
        description = "Build mesa from the git snapshot pinned in git.json.";
      };

      shaderCacheMaxSize = mkStrOption {
        default = shaderCacheMaxSize;
        description = "Max size of the mesa shader cache per user, as a number with a K, M or G suffix. Mesa evicts the oldest entries past it.";
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
          inherit (config.icedos.hardware.graphics.mesa) rc git shaderCacheMaxSize;
        in
        {
          assertions = [
            {
              assertion = !(rc && git);
              message = "icedos.hardware.graphics.mesa: only one of `rc` and `git` can be enabled at a time.";
            }
          ];

          environment.sessionVariables.MESA_SHADER_CACHE_MAX_SIZE = shaderCacheMaxSize;

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
