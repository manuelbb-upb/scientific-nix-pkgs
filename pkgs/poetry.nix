{
  writeShellScriptBin,
  poetry,
  python-patcher,
  python3,
  NIX_LD_LIBRARY_PATH,
  poetry-pre-overrides ? {},
  poetry-post-overrides ? {},
}:
let
  python-patched = if (python3.passthru.is_matlab_patched or false) then python3 else (python-patcher python3);
  python-without-flaky-tests = python-patched.override {
    # `poetry` depends on `virtualenv`.
    # Somehow, our wrapper script (below) -- or some nix machanism --
    # messes with bash output with virtual environments.
    # This causes tests to fail. I dissable them in `packageOverrides`:
    self = python-without-flaky-tests;
    packageOverrides = (fin: (prev: {
      virtualenv = prev.virtualenv.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or []) ++ [
          "test_bash"
        ];
      });
      # `xdist` seems to cause problems non-deterministically...
      # (see, e.g., https://github.com/NixOS/nixpkgs/issues/230597)
      # For me, the following test failed before (in a shell with `numpy`),
      # so I disable them here:
      xdist = prev.pytest-xdist.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or []) ++ [
          "test_max_worker_restart_tests_queued"
        ];
      });
      # Likewise, `watchdog` has some flaky tests...
      # see https://github.com/gorakhargosh/watchdog/issues/973
      watchdog = prev.watchdog.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or []) ++ [
          "test_auto_restart_on_file_change_debounce"
        ];
      });
      pytest-subprocess = prev.pytest-subprocess.overridePythonAttrs (old: {
        disabledTests = (old.disabledTests or []) ++ [
          "test_multiple_wait"
        ];
      });
    }));
  };

  poetry-pre-pre-patched = poetry.override poetry-pre-overrides;
  poetry-pre-patched = poetry-pre-pre-patched.override {
    python3 = python-without-flaky-tests;
  };
  poetry-post-pre-patched = poetry-pre-patched.override poetry-post-overrides;

  poetry-patched = writeShellScriptBin "poetry" ''
      export LD_LIBRARY_PATH="${NIX_LD_LIBRARY_PATH}:''${LD_LIBRARY_PATH}"
      exec -a "$0" "${poetry-post-pre-patched}/bin/poetry" "$@"
  '';
in
  poetry-patched
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
