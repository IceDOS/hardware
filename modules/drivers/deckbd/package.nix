{
  stdenv,
  fetchFromGitHub,
  libevdev,
  glib,
  pkg-config,
  ...
}:

let
  # Upstream never tags; update.sh tracks main's HEAD. See ./update.sh.
  source = builtins.fromJSON (builtins.readFile ./source.json);
in
stdenv.mkDerivation rec {
  name = "deckbd";
  inherit (source) version;

  src = fetchFromGitHub {
    owner = "ninlives";
    repo = name;
    inherit (source) rev hash;
  };

  buildInputs = [
    libevdev
    glib.dev
  ];
  nativeBuildInputs = [ pkg-config ];
  makeFlags = [ "PREFIX=$(out)" ];
}
