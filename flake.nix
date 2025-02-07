{
  description = "Tools for working with Matlab in NixOs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    # As far as I know, Matlab only works on x86:
    system = "x86_64-linux";
    # Propagate function arguments lazily with callPackage pattern, see
    # https://nixos.org/guides/nix-pills/13-callpackage-design-pattern.html
    nixpkgs = import nixpkgs { inherit system; };
    allPkgs = nixpkgs // pkgs;
    callPackage =
      path: overrides:
      let
        f = import path;
      in
        f ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);

    pkgs = rec {
      NIX_LD = callPackage ./pkgs/nix-ld-env-var.nix;
      # define LD_LIBRARY_PATH prefixes and matlab package;
      matlab-set = callPackage ./pkgs/matlab/default.nix {
        dir-env-var = "MATLAB_INSTALL_DIR";
      };
      inherit (matlab-set) matlab_LD_LIBRARY_PATH matlab-shellHook matlab-shell matlab; 
    
      # wrap `tcsh` such that it can be called as `csh`:
      csh = callPackage ./pkgs/csh.nix;

      julia-set = callPackage ./pkgs/julia/default.nix {
        version = "1.11.1";
        sha-for-version = "";
        add-opengl-libs = true;
        enable-matlab = false;
      };
      inherit (julia-set) julia-bin julia-ld;
    };

  in
  rec {
    inherit (pkgs) matlab-shellHook matlab_LD_LIBRARY_PATH NIX_LD;
    # make patched packages availabe:
    packages.${system} = {
      inherit (pkgs) csh julia-bin julia-ld matlab matlab-shell;
    };

    devShells.${system}.default = pkgs.matlab-shell;

    /*
    tools.${system} = {
      inherit (pkgs-patched) python-patcher;
    };

    templates = {
      julia = {
        description = "Devshell with unpatched Julia and preseeded library path";
        path = ./templates/julia;
      };
      python = {
        description = "Devshell with patched Python for nix-ld.";
        path = ./templates/python;
      };
      poetry = {
        description = "Devshell with patched Python and poetry for nix-ld.";
        path = ./templates/poetry;
      };
    };
    */
  };
}
