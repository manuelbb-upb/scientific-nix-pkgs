{
  callOurPackage,
  lib,
  writeShellApplication,
  mkShell,
  NIX_LD,
  dir-env-var ? "MATLAB_INSTALL_DIR",
}:
let
  matlab-deps = callOurPackage ./matlab-deps.nix {};
  matlab_LD_LIBRARY_PATH = lib.makeLibraryPath matlab-deps;

  # Now for the actual Matlab package(s).
  # First, a `shellHook` to setup variables for `nix-ld` and `envfs` to use Matlab.
  # The hook can be used with `mkShell` or sourced in scripts.
  matlab-shellHook = ''
    # prepend custom library path to `NIX_LD_LIBRARY_PATH`:
    export NIX_LD_LIBRARY_PATH="${matlab_LD_LIBRARY_PATH}":''${NIX_LD_LIBRARY_PATH}
    # define dynamic linker:
    NIX_LD="${NIX_LD}"
    export NIX_LD
    # tell `envfs` to simulate files to exist in `/bin` and `/usr/bin`:
    export ENVFS_RESOLVE_ALWAYS=1
  '';

  matlab-shell = mkShell {
    name = "matlab-shell";
    shellHook = matlab-shellHook;
  };
  bin-path = "\${${dir-env-var}}/bin/matlab";

  matlab-pkg = writeShellApplication { 
    name = "matlab";
    passthru = {
      inherit dir-env-var;
      shell = matlab-shell;
      LD_LIBRARY_PATH = matlab_LD_LIBRARY_PATH;
      shellHook = matlab-shellHook;
    };
    text = ''
      ${matlab-shellHook}
      exec -a "$0" "${bin-path}" "$@"
    ''; 
  };
in
matlab-pkg
