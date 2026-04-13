{
  pkgs,
  osConfig,
  ...
}: {
  imports = [
    ./stylix.nix
  ];

  home = {
    username = "purps";
    homeDirectory = "/home/purps";
    stateVersion = "26.05";

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      ripgrep
      fd
      just
      fastfetch
    ];
  };

  custom.programs = {
    helix.enable = true;
    yazi.enable = true;
    fish = {
      enable = true;
      aliases = {
        cp = "cp -i";
        mv = "mv -i";
        mkdir = "mkdir -p";
      };
    };
    git = {
      enable = true;
      userName = "purps";
      userEmail = "github@purps.ca";
    };
    ssh = {
      enable = true;
      githubKeyPath = osConfig.sops.secrets."github-ssh-key".path;
    };
    starship.enable = true;
    lazygit.enable = true;
  };
}
