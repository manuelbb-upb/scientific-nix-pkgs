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
    # Default python: `otherPkgs.python`.
    # Specific version needs to be patched:
    python = tools.python-patcher pkgs.python312;
    
    # Tell poetry to use that version (The wiki tells us to do so, I am not sure if necessary)
    poetry = otherPkgs.poetry.override{
      python3 = python;
    };

  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        python.pkgs.matlab
        poetry
      ];
      shellHook = nix-matlab-ld.ld-shellHook + ''
        export "PY_MATLAB_ENGINE"="${python.pkgs.matlab}/${python.pkgs.matlab.pythonModule.sitePackages}"
      '';
    };
  };
}
