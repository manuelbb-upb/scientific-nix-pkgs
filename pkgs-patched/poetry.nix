{
  python,
  poetry-pkg,
  writeShellScriptBin,
  NIX_LD_LIBRARY_PATH
}:
rec {
  poetry-pre-patched = poetry-pkg.override {
    python3 = python;
  };

  poetry = writeShellScriptBin "poetry" ''
      export LD_LIBRARY_PATH="${NIX_LD_LIBRARY_PATH}:''${LD_LIBRARY_PATH}"
      exec -a "$0" "${poetry-pre-patched}/bin/poetry" "$@"
  '';

#     poetry = pkgs.symlinkJoin {
#       name = "poetry";
#       paths = [ poetry-pre-patched ];
#       buildInputs = [ pkgs.makeWrapper ];
#       postBuild = ''
#         wrapProgram "$out/bin/poetry" --prefix "LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}"
#       '';
#     };
#
#   poetry-patched = pkgs.writeShellScriptBin "poetry" ''
#     export LD_LIBRARY_PATH=${NIX_LD_LIBRARY_PATH}
#     exec ${poetry-pre-patched}/bin/poetry "$@"
#   '';
#   # if you want poetry
#   poetry-patched =  ((poetry.override { python3 = python-patched; }).overrideAttrs (
#     previousAttrs: {
#       # same as above, but for poetry
#       # not that if you dont keep the blank line bellow, it crashes :(
#       postInstall = previousAttrs.postInstall + ''
#         mkdir $out/bin/unpatched
#         mv "$out/bin/poetry" "$out/bin/unpatched/poetry"
#         cat << EOF >> "$out/bin/poetry"
#         #!/usr/bin/env bash
#         export LD_LIBRARY_PATH="${ldlibpath}"
#         exec "$out/bin/unpatched/poetry" "\$@"
#         EOF
#         chmod +x "$out/bin/poetry"
#       '';
#     }
#   ));
}
