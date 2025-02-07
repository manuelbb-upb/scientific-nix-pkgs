{
  callPackage,
  NIX_LD ? "",
  version ? "1.11.1",
  sha-for-version ? "",
  add-opengl-libs ? true,
  enable-matlab ? false,
  matlab_LD_LIBRARY_PATH ? "",
}:
let
  julia-src = callPackage ./julia-fetch-src.nix;

  julia-bin = callPackage ./julia-make-bin.nix;

  julia-ld = callPackage ./julia-prefixed.nix;
in
{
  inherit julia-bin julia-ld;
}
