{osConfig, ...}: {
  imports = [
    ./general.nix
  ];

  custom.theme = {
    enable = true;
    foregroundContrast = "high";
    kdeTargets = true;
  };

  custom.profiles = {
    desktop = {
      enable = true;
      kde = true;
    };
    browsers.enable = true;
    gaming = {
      enable = true;
      slsSteam = true;
    };
    media = {
      enable = true;
      rustdeskServerFile = osConfig.sops.secrets."rustdesk-server".path;
      rustdeskKeyFile = osConfig.sops.secrets."rustdesk-key".path;
    };
    hardware = {
      enable = true;
      username = "inori";
    };
  };

  home.persistence."/persist" = {
    directories = [
      "Downloads"
      "Pictures"
      "Videos"
      "Documents"
    ];
  };
}
