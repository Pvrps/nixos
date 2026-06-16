{
  pkgs,
  osConfig,
  ...
}: {
  imports = [
    ./general.nix
  ];

  custom.theme = {
    enable = true;
    foregroundContrast = "high";
    kdeTargets = true;
  };

  # ---------------------------------------------------------------------------
  # Desktop base (was profiles.desktop): GTK/dconf file chooser, Wayland session
  # vars, gnome-keyring, common persistence. kde = true on this machine.
  # ---------------------------------------------------------------------------
  home = {
    packages = [pkgs.trash-cli];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
      # KDE Plasma adjustment (was profiles.desktop.kde)
      POWERDEVIL_NO_DDCUTIL = "1";
    };

    persistence."/persist" = {
      hideMounts = true;
      directories = [
        ".local"
        ".config"
        ".var"
        ".gnupg"
        ".pki"
        # inori machine-specific persistence
        "Downloads"
        "Pictures"
        "Videos"
        "Documents"
        # GPU shader-cache persistence (was profiles.hardware)
        ".cache/nvidia"
        ".cache/mesa_shader_cache"
        ".cache/radv_builtin_shaders"
      ];
    };
  };

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      show-hidden = true;
      sort-directories-first = true;
    };
    "org/gtk/gtk4/settings/file-chooser" = {
      show-hidden = true;
    };
  };

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-show-hidden = true;
    gtk4.extraConfig.gtk-show-hidden = true;
  };

  # KDE Plasma runs on Wayland via SDDM; set the flag so Wayland-only scripts
  # pass their assertions (was profiles.desktop.kde).
  custom.system.wayland.enable = true;

  custom.programs = {
    gnomeKeyring.enable = true;

    # -------------------------------------------------------------------------
    # Browser (was profiles.browsers): Zen. inori currently uses the same
    # extension set as purps; freely diverge here without affecting anyone else.
    # -------------------------------------------------------------------------
    zen = {
      enable = true;
      homepage = "https://homepage.windwaker.ca/";
      profiles.Personal = {
        id = 0;
        name = "Personal";
        isDefault = true;
        mods = [
          "a6335949-4465-4b71-926c-4a52d34bc9c0"
          "f7c71d9a-bce2-420f-ae44-a64bd92975ab"
          "c6813222-6571-4ba6-8faf-58f3343324f6"
          "253a3a74-0cc4-47b7-8b82-996a64f030d5"
          "906c6915-5677-48ff-9bfc-096a02a72379"
          "cb15abdb-0514-4e09-8ce5-722cf1f4a20f"
          "803c7895-b39b-458e-84f8-a521f4d7a064"
          "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8"
          "e122b5d9-d385-4bf8-9971-e137809097d0"
          "c8d9e6e6-e702-4e15-8972-3596e57cf398"
          "bd92a9a0-1c00-4187-a66e-94c389fa5a59"
        ];
        settings = {
          "mod.autoexpand.expanded_width" = "250px";
          "mod.autoexpand.animation_duration" = "100ms";
          "mod.autoexpand.animation_delay" = "100ms";
          "mod.autoexpand.collapse_delay" = "100ms";
          "mod.autoexpand.hide_workspace_indicator" = true;
        };
      };
      extensionSettings = {
        "*" = {installation_mode = "blocked";};
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
        "enhancerforyoutube@maximerf.addons.mozilla.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi";
          installation_mode = "force_installed";
        };
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
          installation_mode = "force_installed";
        };
        "izer@camelcamelcamel.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/the-camelizer-price-history-ch/latest.xpi";
          installation_mode = "force_installed";
        };
        "webextension@metamask.io" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ether-metamask/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };

    # -------------------------------------------------------------------------
    # Gaming (was profiles.gaming): Steam (+SLSsteam), Discord + plugins, arRPC,
    # bolt, prismlauncher. inori has no niri launcher. Millennium plugins below.
    # -------------------------------------------------------------------------
    steam = {
      enable = true;
      slsSteam.enable = true;
    };
    discord = {
      enable = true;
      plugins = {
        clearUrls.enable = true;
        dearrow.enable = true;
        imageZoom.enable = true;
        onePingPerDm.enable = true;
        pinDms = {
          enable = true;
          canCollapseDmSection = true;
          pinOrder = 1;
        };
        shikiCodeblocks.enable = true;
        betterGifPicker.enable = true;
        biggerStreamPreview.enable = true;
        callTimer.enable = true;
        copyEmojiMarkdown.enable = true;
        copyFileContents.enable = true;
        disableCallIdle.enable = true;
        experiments.enable = true;
        favoriteEmojiFirst.enable = true;
        forceOwnerCrown.enable = true;
        friendsSince.enable = true;
        gameActivityToggle.enable = true;
        memberCount.enable = true;
        mentionAvatars.enable = true;
        messageLogger = {
          enable = true;
          collapseDeleted = true;
          ignoreBots = true;
          ignoreSelf = true;
        };
        noUnblockToJump.enable = true;
        permissionsViewer.enable = true;
        petpet.enable = true;
        platformIndicators.enable = true;
        relationshipNotifier = {
          enable = true;
          notices = true;
        };
        reverseImageSearch.enable = true;
        sendTimestamps.enable = true;
        serverListIndicators.enable = true;
        showConnections.enable = true;
        showHiddenChannels.enable = true;
        showHiddenThings.enable = true;
        silentMessageToggle = {
          enable = true;
          autoDisable = false;
        };
        silentTyping.enable = false;
        startupTimings.enable = true;
        superReactionTweaks.enable = true;
        typingIndicator.enable = true;
        typingTweaks.enable = false;
        unlockedAvatarZoom.enable = true;
        whoReacted.enable = true;
        youtubeAdblock.enable = true;
        streamingCodecDisabler = {
          enable = false;
          disableVp8Codec = false;
          disableVp9Codec = false;
          disableAv1Codec = false;
        };
        fakeNitro = {
          enable = true;
          enableStreamQualityBypass = false;
          enableEmojiBypass = true;
          enableStickerBypass = true;
        };
        volumeBooster.enable = true;
        webScreenShareFixes.enable = true;
      };
    };
    arrpc.enable = true;
    discord-rpc.enable = true;
    bolt.enable = true;
    prismlauncher.enable = true;

    # -------------------------------------------------------------------------
    # Media (was profiles.media, no extras): OBS, Spotify, Stremio, Clapper,
    # Okular, Pinta, Flatseal, RustDesk.
    # -------------------------------------------------------------------------
    stremio.enable = true;
    clapper.enable = true;
    spotify.enable = true;
    okular.enable = true;
    pinta.enable = true;

    rustdesk = {
      enable = true;
      serverFile = osConfig.sops.secrets."rustdesk-server".path;
      keyFile = osConfig.sops.secrets."rustdesk-key".path;
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
        aitumStreamSuite = {
          enable = true;
          version = "1.1.2";
          hash = "sha256:46137e8ec8b92704879c58ed486bede468102935e53d25f3f1a36a5e07c71bca";
        };
        pipewireAudioCapture = {
          enable = true;
          version = "1.2.1";
          hash = "sha256:e3bfa510bf3cfccdba092ee726e7e0d3cbe433dd49d4101f6a3e2b7fa68eae84";
        };
      };
    };

    # -------------------------------------------------------------------------
    # Hardware (was profiles.hardware): EasyEffects (mutable blue_yeti preset +
    # micsave commit tool), OpenRGB. No liquidctl on this machine.
    # -------------------------------------------------------------------------
    easyeffects = {
      enable = true;
      preset = "blue_yeti";
      presetSource = "/persist/etc/nixos/modules/users/inori/files/blue_yeti.json";
    };
    openrgb.enable = true;
  };

  custom.scripts.micsave = {
    enable = true;
    presetGitPath = "/persist/etc/nixos/modules/users/inori/files/blue_yeti.json";
  };

  # Millennium (Steam) plugins (was profiles.gaming). Explicit per-user.
  xdg.dataFile = {
    "millennium/plugins/extendium".source = pkgs.fetchzip {
      url = "https://github.com/BossSloth/Extendium/releases/download/v1.1.1/Extendium-plugin-1.1.1.zip";
      sha256 = "0dg7q27ppzri6vqk24s1v6d6q8d0iicw3igdqc55pc8g050v1pfx";
    };

    "millennium/plugins/achievement-groups".source = pkgs.fetchzip {
      url = "https://github.com/BossSloth/SteamHunter-plugin/releases/download/v2.0.2/Achievement-Groups-plugin-2.0.2.zip";
      sha256 = "18g921w6idswwvbha9dyszki60pv1pvhlzsi817ddps8pifhwpwj";
    };
  };
}
