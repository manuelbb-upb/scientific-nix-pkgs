{
  lib,
  poetry,
  python-ld,
  replaceDependency
}:
replaceDependency {
  drv = poetry;
  oldDependency = poetry.python;
  newDependency = python-ld;
}