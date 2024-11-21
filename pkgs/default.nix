{
  pkgs,
  python-pkg,
  matlab_LD_LIBRARY_PATH,
  NIX_LD,
  julia-version ? "1.11.1",
  julia-sha-for-version ? "",
  julia-enable-matlab ? true,
  julia-add-opengl-libs ? true,
  poetry-pre-overrides ? {},
  poetry-post-overrides ? {},
  root ? "\${MATLAB_INSTALL_DIR}",
}:
let

  csh = pkgs.callPackage ./csh.nix {};
  julia-set = pkgs.callPackage ./julia/default.nix {
    inherit julia-version julia-sha-for-version NIX_LD;
    inherit julia-enable-matlab matlab_LD_LIBRARY_PATH;
    inherit julia-add-opengl-libs;
    tcsh = csh;
  };
  
  python-patcher = pkgs.callPackage ./python.nix {
    inherit root;
    NIX_LD_LIBRARY_PATH = matlab_LD_LIBRARY_PATH;
  };
  python = python-patcher python-pkg;

  poetry = pkgs.callPackage ./poetry.nix {
    inherit python-patcher python-pkg;
    inherit poetry-pre-overrides;
    inherit poetry-post-overrides;
    python3 = python-pkg;
    NIX_LD_LIBRARY_PATH = matlab_LD_LIBRARY_PATH;
  };
in
rec {
  inherit (julia-set) julia-bin julia;
  inherit csh;
  inherit python-patcher python;
  inherit poetry;
}
