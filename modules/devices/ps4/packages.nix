{
  fetchFromGitHub,
  python3,
  stdenv,
}:

let
  ps4MultibootSrc = fetchFromGitHub {
    owner = "blue0x1";
    repo = "ps4-multiboot";
    rev = "82862b2ce63b8664e2b4e4341708c67e607e7b9d";
    hash = "sha256-DGiRY4aQmdtbDUkntG4qqHcZQ3Ax1S/Opy6wCVGB6sc=";
  };

  ps4-bridge = stdenv.mkDerivation {
    pname = "ps4-bridge";
    version = "unstable-2026-11-14";
    src = ps4MultibootSrc;
    buildInputs = [ python3 ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/bin
      cp tools/ps4-bridge.py $out/bin/ps4-bridge
      chmod +x $out/bin/ps4-bridge
      patchShebangs $out/bin/ps4-bridge
    '';
  };

  ps4-hdmi-keepalive = stdenv.mkDerivation {
    pname = "ps4-hdmi-keepalive";
    version = "unstable-2026-11-14";
    src = ps4MultibootSrc;
    buildInputs = [ python3 ];
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/bin
      cp overlay/usr/local/sbin/ps4-hdmi-keepalive $out/bin/ps4-hdmi-keepalive
      chmod +x $out/bin/ps4-hdmi-keepalive
      substituteInPlace $out/bin/ps4-hdmi-keepalive --replace-fail "/usr/local/sbin/ps4-bridge" "${ps4-bridge}/bin/ps4-bridge"
      patchShebangs $out/bin/ps4-hdmi-keepalive
    '';
  };
in
{
  inherit ps4-bridge ps4-hdmi-keepalive;
}
