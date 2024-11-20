{
  runCommand,
  stdenv,
  symlinkJoin,
  fetchurl,
  makeWrapper,
  lib,
  curl,
  NIX_LD_LIBRARY_PATH,
  NIX_LD,
  julia-version ? "1.11.1",
  julia-sha ? "",
}:

let
  # nix hash convert --hash-algo sha256 --from nix32 $(nix-prefetch-url --unpack --type sha256 https://julialang-s3.julialang.org/bin/linux/x64/1.11/julia-1.11.1-linux-x86_64.tar.gz)
  version-sha256 = {
    "1.11.1" = "sha256-zKjRPcRQfk9ioSkyIpMxPuV08wDU3559swt7QcX4qPM=";
    "1.11.0" = "sha256-vPgVVT/aLteRBSTIyqGJyOgZGkCnmd2LX77Q2d1riCw=";
    "1.10.6" = "sha256-i1NCnhdYXGZHaznysiedogfqDzEMVds480EL3U9qPUk=";
    "1.11.0-rc1" = "sha256-2dfKgQhxhau7ijdcQfc03upuomrvLcQNmUZ/jFx8yNY=";
    "1.10.4" = "sha256-B59hdXw7W0DSreBSs8xIFvUPfvbfZogldyVis3Rq3/E=";
    "1.10.1" = "sha256-/pJCWOVdB0QQsTQZXPa4XL6PMH/NBaT90j+JRMWUGnA=";
    "1.10.0" = "sha256-pymCB/cvKyeyqxzjkqbqN6+9H77g8fjRkLBU3KuoeP4=";
    "1.10.0-beta2" = "sha256-8aF/WlKYDBZ0Fsvk7aFEGdgY87dphUARVKOlZ4edZHc=";
    "1.10.0-beta1" = "sha256-zaOKLdWw7GBcwH/6RO/T6f4QctsmUllT0eJPtDLgv08=";
    "1.9.3" = "sha256-12ZwzJuj4P1MFUXdPQAmnAaUl2oRdjEnlevOFpLTI9E=";
    "1.9.2" = "sha256-TC15n0Qtf+cYgnsZ2iusty6gQbnOVfJO7nsTE/V8Q4M=";
    "1.9.0" = "sha256-AMYURm75gJwusjSA440ZaixXf/8nMMT4PRNbkT1HM1k=";
    "1.8.3" = "sha256-M8Owk1b/qiXTMxw2RrHy1LCZROj5P8uZSVeAG4u/WKk=";
    "1.7.2" = "sha256-p1JEck87LeDnJJyGH79kB4JXwW+0IDvnjxz03VlzupU=";
    "1.6.7" = "sha256-bEUi1ZXky80AFXrEWKcviuwBdXBT0gc/mdqjnkQrKjY=";
  };

  fetch-julia-src = version: let
    url = "https://julialang-s3.julialang.org/bin/linux/x64/${
      lib.versions.majorMinor version
    }/julia-${version}-linux-x86_64.tar.gz";
  in fetchurl {
    inherit url;
    sha256 = (if julia-sha == "" then
      (if (builtins.hasAttr version version-sha256) then
        version-sha256.${version}
      else
        version-sha256."1.11.1")
     else
      julia-sha);
  };

  make-julia-from-version = version: runCommand "julia-${version}" {
    src = fetch-julia-src version;
    nativeBuildInputs = [
      makeWrapper   # to have shell script `wrapProgram` available
      /*
      curl          # For the case that shipped libcurl is not used,
                    # we need at least curl 8.11, I think...
                    # https://github.com/curl/curl/issues/14860
                    # https://github.com/JuliaInterop/CxxWrap.jl/issues/407
      */
    ];
  } ''
    mkdir $out
    tar xf $src -C $out --strip-components=1

    chmod -R u+w $out
    chmod a+x $out/bin/julia
    wrapProgram $out/bin/julia \
      --set "NIX_LD_LIBRARY_PATH" "" \
      --set "NIX_LD" "${NIX_LD}" \
      --set "LD_LIBRARY_PATH" "/run/opengl-driver/lib/" \
      --set "LD_PRELOAD" ${stdenv.cc.cc.lib}/lib/libstdc++.so.6
  '';
  /*
        --prefix "NIX_LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}" \
        --prefix "PATH" : "${lib.makeBinPath [ curl ]}"
  */

  julia = make-julia-from-version julia-version;
in
{
  inherit julia;
}




