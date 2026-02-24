_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';

    functions = {
      run = ''
        if string match -q "*.AppImage" $argv[1]
          NIXPKGS_ALLOW_UNFREE=1 nix-shell -p appimage-run --run "appimage-run $argv"
        else
          NIXPKGS_ALLOW_UNFREE=1 nix-shell -p steam-run --run "steam-run $argv"
        end
      '';
    };
  };
}
