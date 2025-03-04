{
  callOurPackage,
  lib,
  runCommand,
  csh,
  NIX_LD,
  matlab,
  version ? "1.11.1",
  sha-for-version ? "",
  add-opengl-libs ? true,
  enable-matlab ? false,
  pre_LD_LIBRARY_PATH ? "",
  post_LD_LIBRARY_PATH ? ""
}:

let
  julia-bin = callOurPackage ./julia-make-bin.nix { inherit version sha-for-version; };

  # If building matlab was actual work, we would have to think about lazyDerivation here:
  matlab_LD_LIBRARY_PATH = lib.optionalString enable-matlab matlab.LD_LIBRARY_PATH;
  matlab-root = if enable-matlab then "\${${matlab.dir-env-var}}" else "";
  # If it weren't for our peculiar needs, we should just set this to the
  # empty string.
  # Our wrapper **replaces** the system-wide `NIX_LD_LIBRARY_PATH` with this
  # string.
  # If there is weird stuff in this path, then Julia will do weird things.
  # It usually is sensitive to fickling with `LD_LIBRARY_PATH`.
  # For `GLMakie` however, we want `/run/opengl-driver/lib` to be visible.
  # That is easy enough.
  # But we also need the `matlab_LD_LIBRARY_PATH` for `MATLAB.jl` to work.
  # Here it gets complicated.
  # We explicitly add the Julia libs to the library path **before** the 
  # system libs, hoping that they get sourced first.
  julia_LD_LIBRARY_PATH = pre_LD_LIBRARY_PATH + 
    "${julia-bin}/lib:${julia-bin}/lib/julia:" +
    lib.optionalString add-opengl-libs "/run/opengl-driver/lib:" +
    matlab_LD_LIBRARY_PATH + 
    post_LD_LIBRARY_PATH;
  
  csh-path = if enable-matlab then "${csh}/bin" else "";
in
runCommand "${julia-bin.pname}-ld-${julia-bin.version}" {
  inherit (julia-bin) pname version;
} ''
  mkdir -p $out/bin
  cat << "EOF" > $out/bin/julia
    #! /usr/bin/env bash
    export PATH="${csh-path}:''${PATH}"
    NIX_LD="${NIX_LD}"
    export NIX_LD
    export NIX_LD_LIBRARY_PATH="${julia_LD_LIBRARY_PATH}"
    export MATLAB_ROOT="${matlab-root}"
    exec -a "$0" "${julia-bin}/bin/julia" "$@"
  EOF
  chmod a+x $out/bin/julia
''
