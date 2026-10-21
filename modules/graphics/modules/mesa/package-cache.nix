# Meson package cache with the crates.io wraps a pinned mesa source lists, as nixpkgs' mesa builds it.
{
  fetchCrate,
  lib,
  runCommand,
}:
wraps:
runCommand "mesa-rust-package-cache" { } ''
  mkdir -p $out
  ${lib.concatMapStringsSep "\n" (
    dep:
    "ln -s ${
      fetchCrate {
        inherit (dep) pname version hash;
        unpack = false;
      }
    } $out/${dep.pname}-${dep.version}.tar.gz"
  ) wraps}
''
