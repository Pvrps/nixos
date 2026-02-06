{pkgs, ...}: {
  imports = [
    ./programs
  ];

  home.username = "purps";
  home.homeDirectory = "/home/purps";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    ripgrep
    fd
  ];

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 5;
    };
  };
}
