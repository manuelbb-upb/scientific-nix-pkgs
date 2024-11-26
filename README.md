**Note** This README is a big ToDo.

This flake provides tools for working with Python, Matlab and Julia on NixOs with 
[`nix-ld`](https://github.com/nix-community/nix-ld) enabled.
For Matlab to work, we also need [`envfs`](https://github.com/nix-community/nix-ld).

# Python

We largely follow the [wiki](https://wiki.nixos.org/wiki/Python) to patch `python` 
to use `LD_LIBRARY_PATH` according to `NIX_LD_LIBRARY_PATH`.
If you use this package, rebuilds will take some time.

Likewise, we patch `poetry` to use our custom python package.
Rebuilds will take even longer.

I have deactivated unit test by default to speed up builds.

# Matlab

## Implementation
Initially inspired by [`nix-matlab`](https://gitlab.com/doronbehar/nix-matlab), 
I wanted to see if we can get away without an FHS.
It appears we can.

We also have a very hacky python package for the patched python.
In constrast to `nix-matlab`, we don't copy engine code to the nix store manually.
Instead, a shim package is generated, with a `.pth` file pointing at the matlab install
location.
Moreover, we exploit the fact that `import` lines in the `.pth` file are executed
to install an import hook that generates the architecture file on import.

## Install

Use `nix develop` with this flake to launch a shell and then install Matlab 
from that shell.
Afterwards, make sure you set the environment variable `MATLAB_INSTALL_DIR`
to point to the install location.
In my home-manager I have
```
home.sessionVariables = {
  MATLAB_INSTALL_DIR = "$HOME/bins/MATLAB/R2024b";
};
```

# Julia

Here we draw inspiration from 
[`scientific-fhs`](https://github.com/olynch/scientific-fhs) to download the julia binaries.

But we don't do any standard `mkDerivation` patching etc.
Instead we wrap the executable to use (nearly) empty `LD_LIBRARY_PATH` and to have 
`NIX_LD` set correctly.

# ToDo

* clean-up
* examples in README
* flake templates
