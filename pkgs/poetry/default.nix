{
  lib,
  poetry,
  python-ld,
  matlab-engine,
  replaceDependency,
}:
let
  old-python = poetry.python;

  ppoetry = replaceDependency {
    drv = poetry;
    oldDependency = old-python;
    newDependency = python-ld;
  };

  mlab-engine = replaceDependency {
    drv = (matlab-engine poetry.python.pkgs);
    oldDependency = old-python;
    newDependency = python-ld;
  };

  mlab-eng-path = "${mlab-engine}/${python-ld.sitePackages}";

  pppoetry = ppoetry // {
    inherit mlab-eng-path;
  };
in
pppoetry
#if export-matlab-engine-var then pppoetry else ppoetry