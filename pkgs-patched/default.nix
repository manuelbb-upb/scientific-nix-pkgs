{
  pkgs,
  lib ? pkgs.lib,
  python-pkg,
  python-execname,
  NIX_LD_LIBRARY_PATH,
  NIX_LD,
  julia-version ? "1.11.1",
  julia-sha ? ""
}:
let
  makeWrapper = pkgs.makeWrapper;
  writeShellScriptBin = pkgs.writeShellScriptBin;
  poetry-pkg = pkgs.poetry;
in
rec {
  python = (import ./python.nix {
    inherit python-pkg python-execname NIX_LD_LIBRARY_PATH makeWrapper;
  }).python;

  poetry = (import ./poetry.nix {
    inherit python NIX_LD_LIBRARY_PATH writeShellScriptBin poetry-pkg;
  }).poetry;

  julia = let
    julia_NIX_LD_LIBRARY_PATH = lib.makeLibraryPath (import ./julia-deps.nix { inherit pkgs; });
  in (pkgs.callPackage ./julia.nix {
    inherit julia-version julia-sha NIX_LD;
    NIX_LD_LIBRARY_PATH = julia_NIX_LD_LIBRARY_PATH;
  }).julia;
}
