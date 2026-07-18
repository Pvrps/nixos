{
  pkgs,
  osConfig,
  ...
}: {
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
      btop
      wget
      jq
    ];
  };

  custom.programs = {
    helix.enable = true;
    yazi.enable = true;
    fish.enable = true;
    git = {
      enable = true;
      userName = "purps";
      userEmail = "github@purps.ca";
      safeDirectories = ["/persist/etc/nixos"];
    };
    ssh = {
      enable = true;
      githubKeyPath = osConfig.sops.secrets."github-ssh-key".path;
    };
    starship.enable = true;
    lazygit.enable = true;
  };
}
