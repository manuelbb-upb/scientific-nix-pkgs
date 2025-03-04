{
  callOurPackage,
  runCommand,
  version ? "1.11.1",
  sha-for-version ? ""
}:
let
  pname = "julia";
  julia-src = callOurPackage ./julia-fetch-src.nix { inherit version sha-for-version; };
  resolved-version = julia-src.version;
in
runCommand "${pname}-${resolved-version}" {
  inherit pname;
  version = resolved-version;
  src = julia-src;
} ''
  mkdir $out
  tar xf $src -C $out --strip-components=1

  chmod -R u+w $out
  chmod a+x $out/bin/julia
''
