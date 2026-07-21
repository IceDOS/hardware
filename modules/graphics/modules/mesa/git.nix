{
  nixpkgs.overlays = [
    (final: super: {
      mesa = super.mesa.overrideAttrs (old: let
        patchDir = ./patches;
        entries = builtins.readDir patchDir;
        patchFiles = builtins.filter (name: builtins.stringLength name > 6 && builtins.substring (builtins.stringLength name - 6) 6 name == ".patch") (builtins.attrNames entries);
        source = builtins.fromJSON (builtins.readFile ./git.json);
      in {
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
      });
    })
  ];
}
