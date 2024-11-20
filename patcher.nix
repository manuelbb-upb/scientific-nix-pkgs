{
  pkgs,
  lib ? pkgs.lib,
}:
{
  python-pkg ? pkgs.python312,
  python-execname ? "python3.12",
  julia-version ? "1.11.1",
  julia-sha ? ""
}:
rec {
  # List of dependencies taken from "nix-matlab" project:
  matlab-deps = import ./matlab-deps.nix;  # a function taking single argument `pkgs`
  # Derive library path:
  NIX_LD_LIBRARY_PATH = lib.makeLibraryPath (matlab-deps pkgs);
  NIX_LD = "\$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)";

  # With library path, we can patch packages (python, poetry, etc.) to
  # use it for `LD_LIBRARY_PATH`:
  custom-pkgs-patched = import ./pkgs-patched/default.nix {
    inherit pkgs lib python-pkg python-execname NIX_LD_LIBRARY_PATH NIX_LD julia-version julia-sha;
  };

  # Now for the actual Matlab package(s).
  # First, a `shellHook` to setup variables for `nix-ld` and `envfs` to use Matlab.
  # The hook can be used with `mkShell` or sourced in scripts.
  ld-shellHook = ''
  # prepend custom library path to `NIX_LD_LIBRARY_PATH`:
  export NIX_LD_LIBRARY_PATH="${NIX_LD_LIBRARY_PATH}":''${NIX_LD_LIBRARY_PATH}
  # define dynamic linker:
  #export NIX_LD="$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)"
  export NIX_LD="${NIX_LD}"
  # tell `envfs` to simulate files to exist in `/bin` and `/usr/bin`:
  export ENVFS_RESOLVE_ALWAYS=1
  '';

  # Function to wrap an exectuable such as to always source the shell script:
  ld-writeShellScriptBin = pkg-name: bin-path: pkgs.writeShellScriptBin pkg-name ''
    ${ld-shellHook}
    exec -a "$0" ${bin-path} "$@"
  '';

  # We can now make the software package for nix:
  matlab-pkg = ld-writeShellScriptBin "matlab" "\${MATLAB_INSTALL_DIR}/bin/matlab";

  # We also want to provide the engine for Python.
  # We have a function generating an editable package when given `python.pkgs`:
  mk-editable-py-pkg-matlab = import ./matlab-python-engine/default.nix {
     inherit pkgs lib;
     pname = "matlab";
     version = "0.0.1";  # required, placeholder
     root = "\\$MATLAB_INSTALL_DIR";
  };

  # Add the package `matlab` to pythons packages:
  python = custom-pkgs-patched.python.override {
    self = python;
    packageOverrides = fin-pkgs: prev-pkgs: {
      matlab = (mk-editable-py-pkg-matlab { py-pkgs = prev-pkgs; });
    };
  };

  # Overwrite patched packages:
  pkgs-patched = custom-pkgs-patched // {
    inherit python;
  };
}

