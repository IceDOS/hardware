{ icedosLib, lib, ... }:

{
  options.icedos.hardware.graphics.mesa =
    let
      inherit (icedosLib) mkBoolOption;
      inherit (lib) readFile;
      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.graphics.mesa) rc git;
    in
    {
      rc = mkBoolOption { default = rc; };
      git = mkBoolOption { default = git; };
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
          inherit (lib) mkIf;
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
        }
      )
    ];

  meta.name = "mesa";
}
