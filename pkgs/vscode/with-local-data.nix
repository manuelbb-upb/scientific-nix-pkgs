{
  pkgs, 
  lib,
  writeTextFile,
  vscode-utils,
  vscodium ? pkgs.vscodium, 
  settings ? {},
  gitignore ? ""
}:

let
  executableName = vscodium.meta.mainProgram; # or somehow use lib.getExe
  wrappedPkgVersion = lib.getVersion vscodium;
  wrappedPkgName = lib.removeSuffix "-${wrappedPkgVersion}" vscodium.meta.name;

  vscode-settings = writeTextFile {
    name = "vscode-settings-json";
    text = builtins.toJSON ((builtins.fromJSON (builtins.readFile ./local_user_data/User/settings.json)) // settings);
    destination = "/settings.json";
  };
  
  vscode-gitignore = writeTextFile {
    name = "vscode-gitignore";
    text = if gitignore == "" then
      builtins.readFile ./local_user_data/.gitignore
    else
      gitignore;
    destination = "/gitignore";
  };
in
writeTextFile {
  name = "${wrappedPkgName}-portable-${wrappedPkgVersion}";
  text = ''
    #!/usr/bin/env bash

    file_path="local_user_data/User/settings.json"
    has_local_data=false

    if [ ! -f "$file_path" ]; then
      read -p "The file '$file_path' does not exist. Do you want to create it? (y/n): " create_file
      if [[ $create_file =~ ^[Yy]$ ]]; then
        mkdir -p local_user_data/User
        cat "${vscode-settings}/settings.json" > "$file_path"
        echo "File created successfully."
        has_local_data=true
      else
        echo "File creation cancelled."
      fi
    else
      has_local_data=true
    fi

    gitignore_path="local_user_data/.gitignore"
    if [ ! -f "$gitignore_path" ]; then
      mkdir -p local_user_data
      cat "${vscode-gitignore}/gitignore" > "$gitignore_path"
    fi
  
    if [ "$has_local_data" = true ] ; then
      local_flag="--user-data-dir ./local_user_data"
    else
      local_flag=""
    fi

    exec -a "$0" ${vscodium}/bin/${executableName} ''${local_flag} "$@"
  '';
  executable = true;
  destination = "/bin/${executableName}";
  meta = vscodium.meta;
  derivationArgs = {
    buildInputs = [
      vscodium
      vscode-settings
      vscode-gitignore
    ];
    dontPatchELF = true;
    dontStrip = true;
  };
}
