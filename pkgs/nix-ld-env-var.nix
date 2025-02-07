{
  lib,
  stdenv,
  NIX_LD ? ""
}:
if NIX_LD != "" then NIX_LD else
  lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";