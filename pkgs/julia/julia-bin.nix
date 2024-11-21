{
  runCommand,
  julia-fetch-src,
  julia-version ? "1.11.1",
  julia-sha-for-version ? "",
}:
let 
  version = julia-version;
  sha-for-version = julia-sha-for-version;
  julia-bin = runCommand "julia-${version}" {
    src = julia-fetch-src version sha-for-version;
  } ''
    mkdir $out
    tar xf $src -C $out --strip-components=1

    chmod -R u+w $out
    chmod a+x $out/bin/julia
 '';
in
  julia-bin
