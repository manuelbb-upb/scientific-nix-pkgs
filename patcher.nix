{
  pkgs,
  python-pkg ? pkgs.python312,
  julia-version ? "1.11.1",
  julia-sha-for-version ? "",
  julia-enable-matlab ? true,
  julia-add-opengl-libs ? true,
}:
let
  lib = pkgs.lib;
in
rec {
  # List of dependencies taken from "nix-matlab" project:
  matlab-deps = import ./matlab-deps.nix;  # a function taking single argument `pkgs`
  # Derive library path:
  matlab_LD_LIBRARY_PATH = lib.makeLibraryPath (matlab-deps pkgs);
  NIX_LD = "\$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)";

  # Now for the actual Matlab package(s).
  # First, a `shellHook` to setup variables for `nix-ld` and `envfs` to use Matlab.
  # The hook can be used with `mkShell` or sourced in scripts.
  ld-shellHook = ''
  # prepend custom library path to `NIX_LD_LIBRARY_PATH`:
  export NIX_LD_LIBRARY_PATH="${matlab_LD_LIBRARY_PATH}":''${NIX_LD_LIBRARY_PATH}
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

  root = "\${MATLAB_INSTALL_DIR}";
  # We can now make the software package for nix:
  matlab-pkg = ld-writeShellScriptBin "matlab" "${root}/bin/matlab";

  # With the matlab library path, we can patch packages (python, poetry, etc.) to
  # use it for `LD_LIBRARY_PATH`:
  pkgs-patched = import ./pkgs/default.nix {
    inherit pkgs python-pkg matlab_LD_LIBRARY_PATH NIX_LD;
    inherit julia-version julia-sha-for-version julia-enable-matlab;
    inherit root;
  };

}
