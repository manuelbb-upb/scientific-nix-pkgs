{
  writeShellScriptBin,
  tcsh,
}:
writeShellScriptBin "csh" ''
  exec -a "$0" ${tcsh}/bin/tcsh "$@"
''
