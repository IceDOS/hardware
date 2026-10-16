{
  nixpkgs.overlays = [
    (final: super: {
      mesa =
        let
          source = builtins.fromJSON (builtins.readFile ./rc.json);
          # "26.2.0-rc3" -> "26.2.0". builtins.compareVersions ranks "-rcN" as
          # *newer* than the bare release, so compare release bases instead.
          rcBase = builtins.head (builtins.split "-" source.version);
          superseded = builtins.compareVersions rcBase super.mesa.version <= 0;
        in
        # Once the release is out the pin is a downgrade. Warn rather than throw so
        # unattended rebuilds keep working; the next RC series re-arms this.
        if superseded then
          final.lib.warn "mesa-rc: pinned RC ${source.version} is not newer than nixpkgs mesa ${super.mesa.version}; using nixpkgs mesa. Bump rc.json or set icedos.hardware.graphics.mesa.rc = false." super.mesa
        else
          (import ./compat.nix {
            inherit (final) lib;
            name = "mesa-rc";
          } super.mesa).overrideAttrs
            (
              old:
              let
                patchDir = ./patches;
                entries = builtins.readDir patchDir;
                patchFiles = builtins.filter (
                  name:
                  builtins.stringLength name > 6
                  && builtins.substring (builtins.stringLength name - 6) 6 name == ".patch"
                ) (builtins.attrNames entries);
              in
              {
                version = source.version;
                src = final.fetchFromGitLab {
                  domain = "gitlab.freedesktop.org";
                  owner = "mesa";
                  repo = "mesa";
                  inherit (source) rev hash;
                };

                patches = map (f: patchDir + "/${f}") patchFiles;

                postPatch = ''
                  patchShebangs .
                '';

                NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=format";
              }
            );
    })
  ];
}
