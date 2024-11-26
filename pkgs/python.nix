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
    
    deactivate-tests = py-pkg: if (
      lib.attrsets.isDerivation py-pkg && builtins.hasAttr "overridePythonAttrs" py-pkg
    ) then
      py-pkg.overridePythonAttrs {
        doCheck = false;
        pythonImportsCheck = [];
      }
    else
      py-pkg;

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
    });

    python-with-or-without-tests = if python-doCheck then
      python-patched
    else
      python-patched.override {
        self = python-patched;
        packageOverrides = (fin-pkgs: prev-pkgs: (
          lib.attrsets.mapAttrs (py-name: py-pkg: (deactivate-tests py-pkg)) prev-pkgs)
        );
      };

    matlab-engine = callPackage ./python-matlab-engine {
      inherit root; 
    };
    python-with-matlab = python-with-or-without-tests.override {
      self = python-with-matlab;
      packageOverrides = py-pkgs-fin: py-pkgs-prev: {
        matlab = (matlab-engine py-pkgs-prev);
      };
    };

    # add attribute `is_matlab_patched` to avoid double patching
    python-with-attrs = python-with-matlab // {
      passthru = python-with-matlab.passthru // {
        patcher-attrs = {
          inherit python-doCheck;
          is_matlab_patched = true;
        };
      };
    };
  in
    python-with-attrs;
in
  python-final
