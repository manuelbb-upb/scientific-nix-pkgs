{
  lib,
  runCommand,
  makeWrapper,
  gnused,
  tcsh,
  #curl,
  NIX_LD,
  julia-bin,
  julia-version ? "1.11.1",
  julia-sha-for-version ? "",
  julia-enable-matlab ? true,
  julia-add-opengl-libs ? true,
  matlab_LD_LIBRARY_PATH ? "",
}:

let
  julia-plain = julia-bin.override {
    inherit julia-version julia-sha-for-version;
  };

  # If it weren't for our peculiar needs, we should just set this to the
  # empty string.
  # Our wrapper **replaces** the systemwide `NIX_LD_LIBRARY_PATH` with this
  # string.
  # If there is weird stuff in this path, then Julia will do strange things.
  # It usually is sensitive to fickling with `LD_LIBRARY_PATH`.
  # For `GLMakie` however, we want `/run/opengl-driver/lib` to be visible.
  # That is easy enough.
  # But we also need the `matlab_LD_LIBRARY_PATH` for `MATLAB.jl` to work.
  # Here it gets complicated.
  # We explicitly add the Julia libs to the library path **before** the 
  # system libs, hoping that they get sourced first.
  julia_LD_LIBRARY_PATH = "" + 
    "${julia-plain}/lib:${julia-plain}/lib/julia:" +
    lib.optionalString julia-add-opengl-libs "/run/opengl-driver/lib:" +
    lib.optionalString julia-enable-matlab matlab_LD_LIBRARY_PATH;

  julia-ld = (runCommand "julia-ld-${julia-version}" {
    buildInputs = [
      julia-plain
      gnused
      tcsh
      makeWrapper   # to have shell script `wrapProgram` available
      
#      curl          # For the case that shipped libcurl is not used,
                    # we need at least curl 8.11, I think...
                    # https://github.com/curl/curl/issues/14860
                    # https://github.com/JuliaInterop/CxxWrap.jl/issues/407
    ];
  } ''
    mkdir $out
    mkdir $out/bin
    ln -s ${julia-plain}/bin/julia $out/bin/julia
    chmod -R u+w $out
    wrapProgram $out/bin/julia \
      --prefix "PATH" : "${tcsh}/bin" \
      --set "NIX_LD" "${NIX_LD}" \
      --set "NIX_LD_LIBRARY_PATH" "${julia_LD_LIBRARY_PATH}" 
    sed -i '2i export "MATLAB_ROOT"="''${MATLAB_INSTALL_DIR}"' $out/bin/julia
  '');
  # ${lib.optionalString julia-enable-matlab "--set-default \"MATLAB_ROOT\" \"\\\${MATLAB_INSTALL_DIR}\" \\ "}
#        --set "LD_PRELOAD" ${stdenv.cc.cc.lib}/lib/libstdc++.so.6
#        --prefix "NIX_LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}" \
#        --prefix "PATH" : "${lib.makeBinPath [ curl ]}"

in
  julia-ld
