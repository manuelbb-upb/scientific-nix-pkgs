{
  description = "Poetry with wrapped Python for Matlab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    scientific-nix-pkgs = {
      url = "github:manuelbb-upb/scientific-nix-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    scientific-nix-pkgs,
    ...
  }:
  let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    spkgs = scientific-nix-pkgs.packages.${system};

    python-ld = spkgs.python-ld.override {
      python3 = pkgs.python312;
    };

    poetry = spkgs.poetry-ld.override {
      inherit python-ld;
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        poetry
      ] ++ (with pkgs; [
        # standard packages here
      ]);
      shellHook = #scientific-nix-pkgs.matlab.shellHook  + 
      ''
        export "PY_MATLAB_ENGINE"="${poetry.mlab-eng-path}"
      '';
    };
  };
}
