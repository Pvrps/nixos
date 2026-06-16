{pkgs, ...}: {
  imports = [];

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
    fish = {
      enable = true;
      aliases = {
        cp = "cp -i";
        mv = "mv -i";
        mkdir = "mkdir -p";
      };
    };
    starship.enable = true;
  };
}
