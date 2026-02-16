{pkgs, ...}: {
  imports = [
    ./programs
    ./scripts
  ];

  home = {
    username = "purps";
    homeDirectory = "/home/purps";
    stateVersion = "26.05";

    packages = with pkgs; [
      ripgrep
      fd
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  services.mako.enable = false;
}
