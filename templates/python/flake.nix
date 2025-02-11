{
  description = "Python wrapped for Matlab";

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

    matlab-engine = scientific-nix-pkgs.matlab-engine;

    python = python-ld.withPackages (py-pkgs: [
      (matlab-engine py-pkgs)
    ] ++ (with py-pkgs; [
      numpy
    ]));
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        python
      ] ++ (with pkgs; [
        # standard packages here
      ]);
      #shellHook = scientific-nix-pkgs.matlab.shellHook;
    };
  };
}
