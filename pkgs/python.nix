{
  lib,
  callPackage,
  makeWrapper,
  NIX_LD_LIBRARY_PATH,
  root ? "\${MATLAB_INSTALL_DIR}",
  python-doCheck ? false,
}:
python-pkg:
let
  python-final = if (
    (python-pkg.passthru.patcher-attrs.is_matlab_patched or false) &&
    ((python-pkg.passthru.patcher-attrs.python-doCheck or (!python-doCheck)) == python-doCheck)
  ) then
    python-pkg
  else let
    # This below does not work... `poetry` needs `python.override`...
    # python = pkgs.symlinkJoin {
    #   name = "python";
    #   paths = [ python-without-virtualenv-test-bash ];
    #   buildInputs = [ pkgs.makeWrapper ];
    #   postBuild = ''
    #     wrapProgram "$out/bin/python3.12" --prefix "LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}"
    #   '';
    # };
    # TODO: `lib.customization.extendDerivation`? ... possibly also issues with overriding ...
    
    python-execname = python-pkg.executable;
    # It seems that we actually need `overrideAttrs` here.
    # (causing a complete rebuild of python and tools depending on it).
    python-patched = python-pkg.overrideAttrs ( previousAttrs: {
      doCheck = python-doCheck;
      nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
        makeWrapper
      ];
      postInstall = previousAttrs.postInstall + ''
        wrapProgram "$out/bin/${python-execname}" --prefix "LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}"
      '';

      passthru = previousAttrs.passthru // {
        patcher-attrs = {
          inherit python-doCheck;
          is_matlab_patched = true;
        };
      };
    });

    deactivate-tests = py-pkg: if (
      lib.attrsets.isDerivation py-pkg && builtins.hasAttr "overridePythonAttrs" py-pkg
    ) then
      py-pkg.overridePythonAttrs {
        doCheck = false;
        pythonImportsCheck = [];
      }
    else
      py-pkg;

    py-pkgs-extension-tests = if python-doCheck then
      (fin-pkgs: prev-pkgs: prev-pkgs)
    else
      (fin-pkgs: prev-pkgs: (
        lib.attrsets.mapAttrs (py-name: py-pkg: (deactivate-tests py-pkg)) prev-pkgs)
      );

    matlab-engine = callPackage ./python-matlab-engine {
      inherit root; 
    };
    py-pkgs-extension-matlab = fin-pkgs: prev-pkgs: {
      matlab = (matlab-engine prev-pkgs);
    };

    python-with-attrs = python-patched.override (old: {
      self = python-with-attrs;
      packageOverrides = lib.composeManyExtensions (
        (if old ? packageOverrides then [ old.packageOverrides ] else []) ++ [ 
          py-pkgs-extension-tests
          py-pkgs-extension-matlab
        ]
      );
    });
  in
    python-with-attrs;
in
  python-final
