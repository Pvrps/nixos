{ pkgs, ... }:
{
  programs.lazygit = {
    enable = true;

    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };
}
