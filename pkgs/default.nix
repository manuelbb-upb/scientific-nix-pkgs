{
  pkgs,
  python-pkg,
  matlab_LD_LIBRARY_PATH,
  NIX_LD,
  python-doCheck ? false,
  julia-version ? "1.11.1",
  julia-sha-for-version ? "",
  julia-enable-matlab ? true,
  julia-add-opengl-libs ? true,
  poetry-pre-overrides ? {},
  poetry-post-overrides ? {},
  root ? "\${MATLAB_INSTALL_DIR}",
}:
let

  inherit (pkgs) lib callPackage;
  csh = callPackage ./csh.nix {};
  julia-set = callPackage ./julia/default.nix {
    inherit julia-version julia-sha-for-version NIX_LD;
    inherit julia-enable-matlab matlab_LD_LIBRARY_PATH;
    inherit julia-add-opengl-libs;
    tcsh = csh;
  };

  matlab-engine-maker = callPackage ./python-matlab-engine {
    inherit root; 
  };
  py-pkgs-extension-matlab = fin-pkgs: prev-pkgs: {
    matlab = (matlab-engine-maker prev-pkgs);
  };
  add-matlab-to-python = python: let
    python-with-matlab = python.override (old: {
      self = python-with-matlab;
      packageOverrides = lib.composeManyExtensions (
        (if old ? packageOverrides then [ old.packageOverrides ] else []) ++ [ 
          py-pkgs-extension-matlab
        ]
      );
    });
  in
    python-with-matlab;
  
  python-patcher = pkgs.callPackage ./python.nix {
    inherit root python-doCheck add-matlab-to-python;
    NIX_LD_LIBRARY_PATH = matlab_LD_LIBRARY_PATH;
  };
  python = python-patcher python-pkg;

  poetry = pkgs.callPackage ./poetry.nix {
    inherit python-patcher;
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
  inherit matlab-engine-maker py-pkgs-extension-matlab add-matlab-to-python;
}
