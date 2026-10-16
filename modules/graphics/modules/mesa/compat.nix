# Drops nixpkgs mesa flags that mesa >= 26.3 rejects. The throws re-arm once nixpkgs catches up.
{ lib, name }:
base:
let
  drivers =
    base.vulkanDrivers
      or (throw "${name}: nixpkgs' mesa no longer exposes passthru.vulkanDrivers — update the vulkanDrivers workaround in compat.nix");
  venusWired =
    lib.any (d: lib.hasInfix "venus" (d.pname or d.name or "")) (
      (base.buildInputs or [ ])
      ++ (base.nativeBuildInputs or [ ])
      ++ (base.depsBuildBuild or [ ])
      ++ (base.propagatedBuildInputs or [ ])
    )
    || lib.hasInfix "venus" ((base.postPatch or "") + toString (base.mesonFlags or [ ]));
in
if venusWired then
  throw "${name}: nixpkgs now wires a venus-protocol package into mesa — remove the vulkanDrivers workaround in compat.nix"
else if !(builtins.elem "virtio" drivers) then
  throw "${name}: nixpkgs' mesa no longer lists 'virtio' in vulkanDrivers — the vulkanDrivers workaround in compat.nix is stale, update or remove it"
else
  base.override {
    # Mesa hard-requires the meson dep "venus-protocol" when virtio is in
    # -Dvulkan-drivers, and nixpkgs has no such package.
    vulkanDrivers = builtins.filter (d: d != "virtio") drivers;
    # Mesa deleted the anti-lag layer (MR 42048, in 26.3); nixpkgs still requests it.
    vulkanLayers = builtins.filter (l: l != "anti-lag") (
      base.vulkanLayers
        or (throw "${name}: nixpkgs' mesa no longer exposes passthru.vulkanLayers — update the vulkanLayers workaround in compat.nix")
    );
  }
