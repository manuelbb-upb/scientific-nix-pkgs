{
  description = "Python Template";

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
    tools = nix-matlab-ld.tools.${system};
    python = tools.python-patcher pkgs.python312; # or `otherPkgs.python` for default version
    poetry = otherPkgs.poetry.override{
      python3 = python;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        python
        poetry
      ];
      shellHook = nix-matlab-ld.ld-shellHook;
    };
  };
}
