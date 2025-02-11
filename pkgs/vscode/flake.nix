{
	description = "VSCode with Default Extensions";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		flake-utils.url = "github:numtide/flake-utils";

		nix-vscode-extensions = {
			url = "github:nix-community/nix-vscode-extensions";
			inputs.nixpkgs.follows = "nixpkgs";
		};

	};

	outputs = { 
		self, 
		nixpkgs, 
		flake-utils, 
		nix-vscode-extensions 
	}@inputs: flake-utils.lib.eachDefaultSystem (system:
		let 
			pkgs = nixpkgs.legacyPackages.${system}; 
			callPackage = pkgs.callPackage;
			
			vs-marketplace-extensions = nix-vscode-extensions.extensions.${system}.vscode-marketplace;
			
			default-extensions =  with vs-marketplace-extensions; [
				# Spacemacs and Vim-Mode
				vspacecode.whichkey
				vspacecode.vspacecode
				vscodevim.vim
				# Random word generator
				thmsrynr.vscode-namegen
				# Catppuccin Theme
				catppuccin.catppuccin-vsc
				# Nix language extension
				jnoortheen.nix-ide
				# direnv chooser:
				mkhl.direnv
			];
			vscodium-with-defaults = callPackage ./with-default-exts {};
			vscodium-local = callPackage ./with-local-data.nix {
				vscodium = vscodium-with-defaults;
			};
		in
		{
			inherit vs-marketplace-extensions;
			packages = {
				inherit vscodium-with-defaults vscodium-local;
			};

			devShells = {
				default = pkgs.mkShell {
					packages = (with pkgs; [
					]) ++ [
						(vscodium-with-defaults.override ( prev: {
							extra-extensions = [];
						}))
					];
				};
			}; 
		}
	);
}
