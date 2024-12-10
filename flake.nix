{
  description = "Tools for working with Matlab in NixOs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    # As far as I know, Matlab only works on x86:
    system = "x86_64-linux";
    # Import packages:
    pkgs = import nixpkgs { inherit system; };

    python-pkg = pkgs.python312;
    python-doCheck = false;
    julia-version = "1.11.1";
    julia-sha-for-version = "";
    julia-add-opengl-libs = true; # so `GLMakie` works
    output-set = import ./patcher.nix {
      inherit pkgs;
      inherit python-pkg python-doCheck;
      inherit julia-version julia-sha-for-version julia-add-opengl-libs;
    };
    pkgs-patched = output-set.pkgs-patched;

  in
  rec {
    inherit (output-set) ld-shellHook;
    inherit (pkgs-patched) add-matlab-to-python py-pkgs-extension-matlab matlab-engine-maker;
    # make patched packages availabe:
    packages.${system} = {
      matlab = output-set.matlab-pkg;
    } // {
      inherit (pkgs-patched) csh python poetry julia;
    };

    devShells.${system}.default = pkgs.mkShell{
      shellHook = ld-shellHook;
    };

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
  };
}
