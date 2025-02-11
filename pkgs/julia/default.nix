{
  callOurPackage,
  NIX_LD,
  matlab,
  version ? "1.11.1",
  sha-for-version ? "",
  add-opengl-libs ? true,
  enable-matlab ? false,
}:
let
  julia-bin = callOurPackage ./julia-make-bin.nix {};

  julia-ld = callOurPackage ./julia-prefixed.nix {};
in
{
  inherit julia-bin julia-ld;
}
