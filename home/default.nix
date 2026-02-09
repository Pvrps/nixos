{pkgs, ...}: {
  imports = [
    ./programs
    ./scripts
  ];

  home = {
    username = "purps";
    homeDirectory = "/home/purps";
    stateVersion = "24.11";

    packages = with pkgs; [
      ripgrep
      fd
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-radius = 5;
    };
  };
}
