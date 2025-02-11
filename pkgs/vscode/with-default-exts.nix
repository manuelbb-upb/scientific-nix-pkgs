{
  vscode-with-extensions,
  default-extensions,
  vscodium,
  extra-extensions ? []
}:
let
  vscodeExtensions = default-extensions ++ extra-extensions;
in
vscode-with-extensions.override {
  inherit vscodeExtensions;
	vscode = vscodium;
}