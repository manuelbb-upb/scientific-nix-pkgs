{
  runCommand,
  julia-src,
  version ? "1.11.1",
}:
let
  pname = "julia"
in
runCommand "${pname}-${version}" {
  inherit pname version;
  src = julia-src;
} ''
  mkdir $out
  tar xf $src -C $out --strip-components=1

  chmod -R u+w $out
  chmod a+x $out/bin/julia
'';