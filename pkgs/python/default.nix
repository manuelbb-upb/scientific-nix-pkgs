{
	replaceDependency,
	runCommand,
	runtimeShell,
	NIX_LD,
	lib,
	python3,
	matlab,
#  add-matlab-engine ? true,
}:
let    
	wpython = let
		py-name = python3.name;
		py-exe = python3.executable;
		py-meta = python3.meta;
	in
	runCommand "${py-name}" {
		passthru = python3.passthru // {
			python = wpython;
			pythonModule = wpython;
			pythonPath = [];
			interpreter = "${wpython}/bin/${py-exe}";
			withPackages = ps: (rep-dep (python3.withPackages ps));
		};
		meta = py-meta;
	} ''
	mkdir -p $out/bin
	# IT IS VERY IMPORTANT THAT THE HEREDOC BELOW IS INDENTED WITH TABS!
	# OTHERWISE THE SHEBANG LINE IS NOT RESPECTED AND BINARY WRAPPERS CANNOT CALL THE SCRIPT
	cat <<-'EOF' > $out/bin/${py-exe}
		#!${runtimeShell}
                NIX_LD="${NIX_LD}"
                export NIX_LD
		export LD_LIBRARY_PATH="${matlab.LD_LIBRARY_PATH}"
		exec -a "$0" "${python3}/bin/${py-exe}" "$@"
	EOF
	chmod a+x $out/bin/${py-exe}
	ln -s "$out/bin/${py-exe}" "$out/bin/python3"
	ln -s "$out/bin/${py-exe}" "$out/bin/python"
	'';

	rep-dep = drv: replaceDependency {
		inherit drv;
		oldDependency = python3;
		newDependency = wpython;
	};
in
	wpython
