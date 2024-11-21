{
  callPackage,
  lib,
  fetchurl,
  tcsh,
  NIX_LD,
  julia-version ? "1.11.1",
  julia-sha-for-version ? "",
  julia-enable-matlab ? true,
  julia-add-opengl-libs ? true,
  matlab_LD_LIBRARY_PATH ? "",
}:
rec {
  julia-fetch-src = import ./julia-fetch-src.nix {
    inherit fetchurl lib;
  };

  julia-bin = callPackage ./julia-bin.nix {
    inherit julia-fetch-src julia-version julia-sha-for-version;
  };

  julia = callPackage ./julia.nix {
    inherit julia-bin julia-version julia-sha-for-version NIX_LD;
    inherit julia-enable-matlab matlab_LD_LIBRARY_PATH;
    inherit julia-add-opengl-libs;
    inherit tcsh;
  };
}
