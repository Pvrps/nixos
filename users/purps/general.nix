{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.stylix.homeModules.stylix
    ./stylix.nix
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
      just
    ];
  };

  custom.programs = {
    helix.enable = true;
    yazi.enable = true;
    fish.enable = true;
    git.enable = true;
    ssh.enable = true;
    starship.enable = true;
    lazygit.enable = true;
  };

  custom.programs.git = {
    userName = "purps";
    userEmail = "github@purps.ca";
  };

  custom.programs.ssh = {
    githubKeyPath = "/run/secrets/github-ssh-key";
  };

  custom.programs.fish = {
    aliases = {
      cp = "cp -i";
      mv = "mv -i";
      mkdir = "mkdir -p";
    };
  };
}