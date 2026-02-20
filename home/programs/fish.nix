_: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';

    functions = {
      run = ''
        NIXPKGS_ALLOW_UNFREE=1 nix-shell -p steam-run --run "steam-run $argv"
      '';
    };

  };
}
