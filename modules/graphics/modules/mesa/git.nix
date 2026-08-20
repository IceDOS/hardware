{
  nixpkgs.overlays = [
    (final: super: {
      # mesa-git hard-requires the meson dep "venus-protocol" when virtio is in
      # -Dvulkan-drivers, and nixpkgs has no such package. The throws below re-arm it.
      mesa =
        let
          base = super.mesa;
          drivers =
            base.vulkanDrivers
              or (throw "mesa-git: nixpkgs' mesa no longer exposes passthru.vulkanDrivers — update the vulkanDrivers workaround in git.nix");
          venusWired =
            final.lib.any (d: final.lib.hasInfix "venus" (d.pname or d.name or "")) (
              (base.buildInputs or [ ])
              ++ (base.nativeBuildInputs or [ ])
              ++ (base.depsBuildBuild or [ ])
              ++ (base.propagatedBuildInputs or [ ])
            )
            || final.lib.hasInfix "venus" ((base.postPatch or "") + toString (base.mesonFlags or [ ]));
        in
        if venusWired then
          throw "mesa-git: nixpkgs now wires a venus-protocol package into mesa — remove the vulkanDrivers workaround in git.nix"
        else if !(builtins.elem "virtio" drivers) then
          throw "mesa-git: nixpkgs' mesa no longer lists 'virtio' in vulkanDrivers — the vulkanDrivers workaround in git.nix is stale, update or remove it"
        else
          (base.override {
            vulkanDrivers = builtins.filter (d: d != "virtio") drivers;
          }).overrideAttrs
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
                source = builtins.fromJSON (builtins.readFile ./git.json);
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
