{
  description = "Unpatched Julia binary wrapped with env vars in dev shell.";

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
    julia = spkgs.julia-ld.override {
      version = "1.12.4";     # julia version to download
      sha-for-version = "";   # sha-256 hash in case the version is not yet registered in `scientific-nix-pkgs`
                              # nix hash convert --hash-algo sha256 --from nix32 $(nix-prefetch-url --type sha256 https://julialang-s3.julialang.org/bin/linux/x64/1.12/julia-1.12.5-linux-x86_64.tar.gz)
      add-opengl-libs = true; # modify NIX_LD_LIBRARY_PATH to include opengl drivers for GLMakie etc.
      enable-matlab = false;   # whether to 
                              # * add matlab paths to NIX_LD_LIBRARY_PATH 
                              # * install csh/tcsh
                              # * set MATLAB_ROOT env variable
      pre_LD_LIBRARY_PATH = "";   # prefix string
      post_LD_LIBRARY_PATH = "";  # suffix string
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        julia
      ] ++ (with pkgs; [

      ]);
      #shellHook = spkgs.matlab.shellHook;
    };
  };
}
