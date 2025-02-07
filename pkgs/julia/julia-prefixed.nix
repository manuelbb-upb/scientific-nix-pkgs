{
  lib,
  runCommand,
  makeWrapper,
  csh,
  NIX_LD ? "",
  julia-bin,
  add-opengl-libs ? true,
  enable-matlab ? false,
  matlab_LD_LIBRARY_PATH ? "",
}:

let

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
  julia_LD_LIBRARY_PATH = "" + 
    "${julia-bin}/lib:${julia-bin}/lib/julia:" +
    lib.optionalString add-opengl-libs "/run/opengl-driver/lib:" +
    lib.optionalString enable-matlab matlab_LD_LIBRARY_PATH;

  NIX_LD = callPackage ../nix-ld-env-var.nix;
  
  csh-path = if enable-matlab then "${csh}/bin" else "";
in
runCommand "${julia-bin.pname}-ld-${julia-bin.version}" {
  inherit (julia-bin) pname version;
  buildInputs = [
    julia-bin
    tcsh
    makeWrapper   # to have shell script `wrapProgram` available
  ];
} ''
  mkdir $out
  mkdir $out/bin
  ln -s ${julia-bin}/bin/julia $out/bin/julia
  chmod -R u+w $out
  wrapProgram $out/bin/julia \
    --prefix "PATH" : "${csh-path}" \
    --set "NIX_LD" "${NIX_LD}" \
    --set "NIX_LD_LIBRARY_PATH" "${julia_LD_LIBRARY_PATH}" \
    --set "MATLAB_ROOT" "''${MATLAB_INSTALL_DIR}"
''