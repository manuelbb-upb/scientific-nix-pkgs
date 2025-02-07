{
  callPackage,
  lib,
  writeShellScriptBin,
  mkShell,
  NIX_LD ? "",
  dir-env-var ? "MATLAB_INSTALL_DIR",
}:
let
  NIX_LD = callPackage ../nix-ld-env-var.nix;
  matlab-deps = callPackage ./matlab-deps.nix;
  matlab_LD_LIBRARY_PATH = lib.makeLibraryPath matlab-deps;

  # Now for the actual Matlab package(s).
  # First, a `shellHook` to setup variables for `nix-ld` and `envfs` to use Matlab.
  # The hook can be used with `mkShell` or sourced in scripts.
  matlab-shellHook = ''
  # prepend custom library path to `NIX_LD_LIBRARY_PATH`:
  export NIX_LD_LIBRARY_PATH="${matlab_LD_LIBRARY_PATH}":''${NIX_LD_LIBRARY_PATH}
  # define dynamic linker:
  export NIX_LD="${NIX_LD}"
  # tell `envfs` to simulate files to exist in `/bin` and `/usr/bin`:
  export ENVFS_RESOLVE_ALWAYS=1
  '';

  matlab-shell = mkShell {
    shellHook = matlab-shellHook;
  };
  bin-path = "\${${dir-env-var}}/bin/matlab";

  matlab = writeShellScriptBin "matlab" ''
    ${matlab-shellHook}
    exec -a "$0" ${bin-path} "$@"
  ''; 
in
{
  inherit matlab_LD_LIBRARY_PATH matlab-shellHook matlab-shell matlab;
}