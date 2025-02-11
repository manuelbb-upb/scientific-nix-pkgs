{
  callOurPackage,
  runCommand,
  version ? "1.11.1",
  sha-for-version ? ""
}:
let
  pname = "julia";
  julia-src = callOurPackage ./julia-fetch-src.nix {};
in
runCommand "${pname}-${version}" {
  inherit pname version;
  src = julia-src;
} ''
  mkdir $out
  tar xf $src -C $out --strip-components=1

  chmod -R u+w $out
  chmod a+x $out/bin/julia
''