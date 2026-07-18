{osConfig, ...}: {
  imports = [
    ./general.nix
  ];

  custom.theme = {
    enable = true;
    foregroundContrast = "high";
    kdeTargets = true;
  };

  custom.profiles.desktop.enable = true;

  custom.programs = {
    kde.enable = true;
    gnomeKeyring.enable = true;

    zen = {
      enable = true;
      homepage = "https://homepage.windwaker.ca/";
    };

    steam = {
      enable = true;
      slsSteam.enable = true;
    };
    discord.enable = true;
    arrpc.enable = true;
    discordRpc.enable = true;
    bolt.enable = true;
    prismlauncher.enable = true;

    stremio.enable = true;
    clapper.enable = true;
    spotify.enable = true;
    okular.enable = true;
    pinta.enable = true;

    linuxWallpaperengine.enable = true;
    rustdesk = {
      enable = true;
      autoStart = true;
      serverFile = osConfig.sops.secrets."rustdesk-server".path;
      keyFile = osConfig.sops.secrets."rustdesk-key".path;
      passwordFile = osConfig.sops.secrets."rustdesk-password".path;
    };

    flatpak = {
      enable = true;
      packages = [
        "com.github.tchx84.Flatseal"
      ];
    };

    obs = {
      enable = true;
      plugins = {
        pipewireAudioCapture.enable = true;
      };
    };

    easyeffects = {
      enable = true;
      preset = "blue_yeti";
      presetSource = "/persist/etc/nixos/modules/users/inori/files/blue_yeti.json";
    };
    openrgb.enable = true;

    # Streams her processed mic (post-EasyEffects) to navi over Tailscale so
    # purps can capture her voice in OBS without unmuting her on Discord
    # (she stays muted there to avoid a room-echo loop for remote friends).
    micStream = {
      enable = false;
      mode = "sender";
      sourceNode = "easyeffects_source";
      remoteHost = "navi";
    };
  };

  custom.scripts.micsave = {
    enable = true;
    presetGitPath = "/persist/etc/nixos/modules/users/inori/files/blue_yeti.json";
  };
}
