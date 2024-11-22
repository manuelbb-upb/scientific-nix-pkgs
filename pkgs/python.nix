{
  callPackage,
  makeWrapper,
  NIX_LD_LIBRARY_PATH,
  root ? "\${MATLAB_INSTALL_DIR}",
}:
python-pkg:
let
  python-execname = python-pkg.executable;
  # This does not work... `poetry` needs `python.override`...
  # python = pkgs.symlinkJoin {
  #   name = "python";
  #   paths = [ python-without-virtualenv-test-bash ];
  #   buildInputs = [ pkgs.makeWrapper ];
  #   postBuild = ''
  #     wrapProgram "$out/bin/python3.12" --prefix "LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}"
  #   '';
  # };
  # TODO: `lib.customization.extendDerivation`? ... possibly also issues with overriding ...

  python-patched = python-pkg.overrideAttrs ( previousAttrs: {
    # It seems that we actually need `overrideAttrs` here.
    # (causing a complete rebuild of python and tools depending on it).
    nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [
      makeWrapper
    ];
    postInstall = previousAttrs.postInstall + ''
      wrapProgram "$out/bin/${python-execname}" --prefix "LD_LIBRARY_PATH" : "${NIX_LD_LIBRARY_PATH}"
    '';
  });

  matlab-engine = callPackage ./python-matlab-engine {
    inherit root;
  };
  python-with-matlab = python-patched.override {
    self = python-patched;
    packageOverrides = py-pkgs-fin: py-pkgs-prev: {
      matlab = (matlab-engine py-pkgs-prev);
    };
  };

  python-final = python-with-matlab // {
    passthru = python-with-matlab.passthru // {
      is_matlab_patched = true;
    };
  };

in
  python-final
