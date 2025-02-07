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

    mpython = (nix-matlab-ld.add-matlab-to-python pkgs.python312).withPackages (py-pkgs: with py-pkgs; [matlab]);

    ppython = (pkgs.symlinkJoin {
      name = "${mpython.name}";
      paths = [ mpython ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/python3.12" --prefix "LD_LIBRARY_PATH" : "${nix-matlab-ld.matlab_LD_LIBRARY_PATH}"
        #ln -s "$out/bin/python3.12" "$out/bin/python"
      '';
    });

    pppython = pkgs.replaceDependency {
      drv = pkgs.python312;
      oldDependency = pkgs.python312;
      newDependency = ppython;
    };
    
    # Tell poetry to use that version (The wiki tells us to do so, I am not sure if necessary)
    poetry = otherPkgs.poetry.override{
      python3 = python;
    };

    ppoetry = pkgs.replaceDependency {
      drv = pkgs.poetry; 
      oldDependency = pkgs.python312;
      newDependency = ppython;
    };

  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        ppython
        #ppoetry
      ];
      shellHook = nix-matlab-ld.ld-shellHook + ''
        export "PY_MATLAB_ENGINE"="${python.pkgs.matlab}/${python.pkgs.matlab.pythonModule.sitePackages}"
      '';
    };
  };
}
