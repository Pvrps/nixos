{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.stylix.homeModules.stylix
    ./stylix.nix
    ../../../modules/home-manager
  ];

  home = {
    username = "purps";
    homeDirectory = "/home/purps";
    stateVersion = "26.05";

    packages = with pkgs; [
      ripgrep
      fd
      nerd-fonts.jetbrains-mono
      noto-fonts
    ];
  };

  custom = {
    programs = {
      helix.enable = true;
      yazi.enable = true;
      fish.enable = true;
      git.enable = true;
      starship.enable = true;
      lazygit.enable = true;
    };

    programs.git = {
      userName = "purps";
      userEmail = "github@purps.ca";
    };
    programs.fish = {
      aliases = {
        cp = "cp -i";
        mv = "mv -i";
        mkdir = "mkdir -p";
      };
    };
  };
}
