{
  description = "Tools for working with Matlab in NixOs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    vscode-local = {
      url = "./pkgs/vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, vscode-local }:
  let
    # As far as I know, Matlab only works on x86:
    system = "x86_64-linux";
    # Propagate function arguments lazily with callPackage pattern, see
    # https://nixos.org/guides/nix-pills/13-callOurPackage-design-pattern.html
    npkgs = import nixpkgs { inherit system; };
    allPkgs = npkgs // pkgs;
    callOurPackage =
      path: overrides:
      let
        f = import path;
      in
        npkgs.lib.makeOverridable f ((builtins.intersectAttrs (builtins.functionArgs f) allPkgs) // overrides);
    
    pkgs = with npkgs; rec {
      inherit callOurPackage;
      
      NIX_LD = callOurPackage ./pkgs/nix-ld-env-var.nix {};
      
      matlab = callOurPackage ./pkgs/matlab/default.nix {
        dir-env-var = "MATLAB_INSTALL_DIR";
      };
      
      # wrap `tcsh` such that it can be called as `csh`:
      csh = callOurPackage ./pkgs/csh/default.nix {};

      julia-set = callOurPackage ./pkgs/julia/default.nix {
        version = "1.11.2";       # julia version to download
        sha-for-version = "";     # sha-256 string for version not yet indexed here
        add-opengl-libs = true;   # modify LD_LIBRARY_PATH to include opengl drivers
        enable-matlab = false;    # modify LD_LIBRARY_PATH to support MATLAB
      };
      inherit (julia-set) julia-bin julia-ld;

      python-ld = callOurPackage ./pkgs/python/default.nix {};

      matlab-engine = callOurPackage ./pkgs/python-matlab-engine/default.nix {};

      python-with-mlab = python-ld.withPackages (pypkgs: [ (matlab-engine pypkgs) ]);

      poetry-ld = callOurPackage ./pkgs/poetry/default.nix {};
    };

    vpkgs = vscode-local.packages.${system};
    vs-marketplace-extensions = vscode-local.${system}.vs-marketplace-extensions;
  in
  rec {
    inherit (pkgs) NIX_LD matlab-engine;
    inherit vs-marketplace-extensions;
    # make patched packages availabe:
    packages.${system} = {
      inherit (pkgs) csh julia-bin julia-ld matlab python-ld python-with-mlab poetry-ld;
      inherit (vpkgs) vscodium-with-defaults vscodium-local;
    };

    devShells.${system}.default = pkgs.matlab.shell;

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
  };
}
