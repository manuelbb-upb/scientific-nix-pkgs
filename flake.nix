{
  description = "Tools for working with Matlab in NixOs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    # As far as I know, Matlab only works on x86:
    system = "x86_64-linux";
    # Import packages and lib:
    pkgs = import nixpkgs { inherit system; };
    lib = pkgs.lib;

    output-function = import ./patcher.nix {
      inherit pkgs lib;
    };

    python-pkg = pkgs.python312;
    python-execname = "python3.12";
    julia-version = "1.11.1";
    julia-sha = "";
    output-set = output-function {
      inherit python-pkg python-execname;
      inherit julia-version julia-sha;
    };

  in
  rec {
    # make patched packages availabe as flake output
    inherit output-function;
    inherit (output-set) pkgs-patched matlab-pkg ld-shellHook;

    packages.${system} = {
      matlab = matlab-pkg;
    } // pkgs-patched ;

    devShells.${system}.default = pkgs.mkShell{
      shellHook = ld-shellHook;
    };
  };
}
