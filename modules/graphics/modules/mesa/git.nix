{
  nixpkgs.overlays = [
    (final: super: {
      mesa =
        (import ./compat.nix {
          inherit (final) lib;
          name = "mesa-git";
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
              source = builtins.fromJSON (builtins.readFile ./git.json);
              virtioFlag = "-Damdgpu-virtio=true";
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

              # Mesa main made amdgpu-virtio a deprecated alias of the amd-options array, which rejects "true".
              mesonFlags =
                if builtins.elem virtioFlag old.mesonFlags then
                  map (f: if f == virtioFlag then "-Damd-options=use-llvm,virtio" else f) old.mesonFlags
                else
                  throw "mesa-git: nixpkgs' mesa no longer passes ${virtioFlag}, update the amd-options workaround in git.nix";

              env = (old.env or { }) // {
                MESON_PACKAGE_CACHE_DIR = import ./package-cache.nix {
                  inherit (final) fetchCrate lib runCommand;
                } source.wraps;
              };

              postPatch = ''
                patchShebangs .
              '';

              NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=format";
            }
          );
    })
  ];
}
