{
  lib,
  stdenv,
}:
let 
  #env-var = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
  env-var = "$(cat '${stdenv.cc}/nix-support/dynamic-linker')";
in
  env-var
