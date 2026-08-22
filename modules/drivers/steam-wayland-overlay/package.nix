{
  cmake,
  fetchFromGitHub,
  pkg-config,
  stdenv,
  wayland,
  wayland-scanner,
  libX11,
  vulkan-headers,
  libffi,
  jq,
}:

let
  vkroots = fetchFromGitHub {
    owner = "misyltoad";
    repo = "vkroots";
    rev = "ee76e620798612c52fb8dcc32a1058a0a3538930";
    hash = "sha256-E+8Uz3ViMMPZ1sLLz7YXbdDgDo9jCD+KR9x8TEpbECA=";
  };

  proton-src = fetchFromGitHub {
    owner = "GloriousEggroll";
    repo = "proton-ge-custom";
    rev = "15e28c57d0b32fbfe67d0e08885383d0a055a972";
    hash = "sha256-hC6IyOSBN8y/u15ORRz/R0+FhHnXniO5SeW7SsvSdtM=";
    sparseCheckout = [ "vklayers/steam-overlay-wayland" ];
  };
in
stdenv.mkDerivation {
  pname = "steam-overlay-wayland";
  version = "1.0.0";

  src = proton-src;
  sourceRoot = "source/vklayers/steam-overlay-wayland";

  nativeBuildInputs = [
    cmake
    jq
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    wayland
    libX11
    vulkan-headers
    libffi
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=release"
    "-DVKROOTS_INCLUDE_DIR=${vkroots}"
    "-DVULKAN_HEADERS_INCLUDE_DIR=${vulkan-headers}/include"
  ];

  postInstall = ''
    JSON=$out/share/vulkan/implicit_layer.d/VkLayer_GE_wayland_steam_overlay.json

    # Only absolutise library_path: the loader requires disable_environment on
    # implicit layers and silently skips the layer without it.
    jq --arg out "${placeholder "out"}" '
      .layer.library_path = ($out + "/lib/libVkLayer_GE_Wayland_SteamOverlay.so")
    ' "$JSON" > "$JSON.tmp" && mv "$JSON.tmp" "$JSON"
  '';
}
