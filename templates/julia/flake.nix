{
  description = "Julia Template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-matlab-ld = {
      url = "github:manuelbb-upb/nix-matlab-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nix-matlab-ld,
    ...
  }:
  let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    otherPkgs = nix-matlab-ld.packages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        (otherPkgs.julia.override {
          julia-version = "1.11.1";
          julia-enable-matlab = true;
          julia-add-opengl-libs = true;
        })
        otherPkgs.csh
      ];
      shellHook = nix-matlab-ld.ld-shellHook;
    };
  };
}
