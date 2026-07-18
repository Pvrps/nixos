{pkgs, ...}: {
  home = {
    username = "inori";
    homeDirectory = "/home/inori";
    stateVersion = "26.05";

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      fastfetch
    ];
  };

  custom.programs = {
    fish.enable = true;
    starship.enable = true;
  };
}
