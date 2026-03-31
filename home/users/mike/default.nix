{pkgs, ...}: {
  home = {
    username = "mike";
    homeDirectory = "/home/mike";
    stateVersion = "26.05";
  };

  programs.firefox = {
    enable = true;
    policies = {
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
}
