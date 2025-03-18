{
	formats,
	lib,
	matlab,
	pname ? "matlab",
	version ? "0.0.1",
}:
py-pkgs:
let
	# The file `path_hook.py` defines a hook for `sys.meta_path` to
	# generate the architecture file if `matlab` or `matlab.engine` is
	# imported in Python.
	# We provide it as a source file for our shim package.
	# This can be done as follows:
	fs = lib.fileset;
	path_hook_src = fs.toSource {
		root = ./.;
		fileset = ./path_hook.py;
	};

	# Most of the code below is copied from 
	# `pkgs/development/interpreters/python/editable.nix`.
	# Our shim package also only is a `.pth` file pointing to the real
	# engine code.
	# Usually, build variable `${root}` is an escaped environment variable 
	# (like MATLAB_INSTALL_DIR).
	# In the build environment, this variable is not accessible.
	# But the `_matlab.pth` file is sourced after build.
	# Python can expand the environment variable and then import `matlab`.
	# To keep this dynamic behavior, we do not make `_matlab.pth` part of the
	# `src` files for the build, as we would have to do manipulations on the 
	# file anyways in the `unpackPhase`.
	pyproject = {
		project = {
			inherit version;
			name = pname;
			requires-python = ">=3.8";
		};
		# Allow empty package
		tool.hatch.build.targets.wheel.bypass-selection = true;

		# Include our editable pointer file in build
		tool.hatch.build.targets.wheel.force-include."_${pname}.pth" = "_${pname}.pth";

		# Also include the hook
		tool.hatch.build.targets.wheel.force-include."path_hook.py" = "path_hook.py";

		# Also copy pyproject.toml for poetry trick 
		tool.hatch.build.targets.wheel.force-include."pyproject.toml" = "pyproject.toml";

		# Build editable package using hatchling
		build-system = {
			requires = [ "hatchling" ];
			build-backend = "hatchling.build";
		};
	};

	pyproject-toml = (formats.toml {}).generate "pyproject.toml" pyproject;
in
	py-pkgs.buildPythonPackage {
		inherit pname version;
		src = path_hook_src;
		pyproject = true;
		build-system = [
			py-pkgs.hatchling
		];
		preferLocalBuild = true;
		
		unpackPhase = ''
			# Make hook file available
			cp $src/path_hook.py path_hook.py

			# Copy the generated toml file
			cp ${pyproject-toml} pyproject.toml

			# Write `_matlab.pth`.
			# Lines starting with `import` are executed.
			cat <<- "EOF" > "_${pname}.pth"
			import os, sys; sys.path.insert(0, os.path.join(os.path.expandvars("''$${matlab.dir-env-var}"), "extern", "engines", "python", "dist"));
			import path_hook	# executes code to prepend to sys.meta_path
			EOF
		'';
	}
