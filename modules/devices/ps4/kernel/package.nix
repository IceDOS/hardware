{
  lib,
  linuxManualConfig,
  llvmPackages,
  src,
  ...
}@args:

let
  llvmStdenv = llvmPackages.stdenv.override {
    cc = llvmPackages.clang.override {
      bintools = llvmPackages.bintools;
    };
  };
in
(linuxManualConfig (
  (removeAttrs args [
    "lib"
    "linuxManualConfig"
    "llvmPackages"
  ])
  // {
    inherit src;
    version = "7.3.3";
    modDirVersion = "7.3.3-Strawberry-PS4-";
    pname = "linux-ps4";
    stdenv = llvmStdenv;
    configfile = ./config;
    allowImportFromDerivation = false;

    kernelPatches = if lib.isList (args.kernelPatches or null) then args.kernelPatches else [ ];

    features = {
      ia32Emulation = true;
    }
    // (args.features or { });

    # Out-of-tree modules split these flags on spaces; -march=btver2 already sets the tuning.
    extraMakeFlags = [
      "KCFLAGS=-march=btver2"
      "KAFLAGS=-march=btver2"
      "LLVM=1"
      "LLVM_IAS=1"
    ];

    extraMeta = {
      description = "Linux kernel for PlayStation 4 (Strawberry branch)";
      platforms = [ "x86_64-linux" ];
    };
  }
)).overrideAttrs
  (old: {
    passthru = (old.passthru or { }) // {
      inherit src;
    };
  })
