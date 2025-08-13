{
  stdenv,
  fetchFromGitHub,
  libevdev,
  glib,
  pkg-config,
  ...
}:

stdenv.mkDerivation rec {
  name = "deckbd";
  version = "git";

  src = fetchFromGitHub {
    owner = "ninlives";
    repo = name;
    rev = "327a8c91159e1b7faa2f12b5e11060b2eb9947a8";
    sha256 = "T7iYl1xWtk39XMUUWm1pK0WVm5UK656HmqWHKDmJ220=";
  };

  buildInputs = [
    libevdev
    glib.dev
  ];
  nativeBuildInputs = [ pkg-config ];
  makeFlags = [ "PREFIX=$(out)" ];
}
