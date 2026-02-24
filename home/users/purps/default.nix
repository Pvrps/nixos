{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.stylix.homeModules.stylix

    ./stylix.nix

    ../../../modules/home-manager/custom.nix

    ../../../modules/home-manager/programs/helix.nix
    ../../../modules/home-manager/programs/noctalia.nix
    ../../../modules/home-manager/programs/niri.nix
    ../../../modules/home-manager/programs/yazi.nix
    ../../../modules/home-manager/programs/fish.nix
    ../../../modules/home-manager/programs/foot.nix
    ../../../modules/home-manager/programs/fuzzel.nix
    ../../../modules/home-manager/programs/git.nix
    ../../../modules/home-manager/programs/starship.nix
    ../../../modules/home-manager/programs/ssh.nix
    ../../../modules/home-manager/programs/zen.nix
    ../../../modules/home-manager/programs/steam.nix
    ../../../modules/home-manager/programs/discord.nix
    ../../../modules/home-manager/programs/opencode.nix
    ../../../modules/home-manager/programs/lazygit.nix
    ../../../modules/home-manager/programs/clapper.nix
    ../../../modules/home-manager/programs/imv.nix
    ../../../modules/home-manager/programs/rustdesk.nix
    ../../../modules/home-manager/programs/java.nix
    ../../../modules/home-manager/programs/prismlauncher.nix
    ../../../modules/home-manager/programs/flatpak.nix
    ../../../modules/home-manager/programs/kilocodecli.nix
    ../../../modules/home-manager/programs/easyeffects
    ../../../modules/home-manager/programs/sidecar.nix

    ../../../modules/home-manager/scripts/capture.nix
    ../../../modules/home-manager/scripts/gitingest.nix
    ../../../modules/home-manager/scripts/micsave.nix
  ];

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
    gtk3.extraConfig = {
      gtk-show-hidden = true;
    };
    gtk4.extraConfig = {
      gtk-show-hidden = true;
    };
  };

  home = {
    username = "purps";
    homeDirectory = "/home/purps";
    stateVersion = "26.05";

    packages = with pkgs; [
      ripgrep
      fd
      nerd-fonts.jetbrains-mono
      noto-fonts
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  custom = {
    git = {
      userName = "purps";
      userEmail = "github@purps.ca";
    };
    easyeffects = {
      preset = "blue_yeti";
      presetSource = ../../../modules/home-manager/programs/easyeffects/blue_yeti.json;
    };
    niri = {
      startupCommands = [
        ''"${pkgs.xwayland-satellite}/bin/xwayland-satellite" ":11"''
        ''"${pkgs.gnome-keyring}/bin/gnome-keyring-daemon" "--start" "--components=secrets"''
        ''"noctalia-shell"''
        ''"bash" "-c" "for i in {1..20}; do ${pkgs.pulseaudio}/bin/pactl list short sources | grep -q 'rnnoise_source' && { ${pkgs.pulseaudio}/bin/pactl set-default-source rnnoise_source; break; }; sleep 0.5; done"''
        ''"bash" "-c" "nm-online -q --timeout=30 || true; steam -system-composer -silent > /dev/null 2>&1"''
        ''"bash" "-c" "nm-online -q --timeout=30 || true; vesktop --start-minimized > /dev/null 2>&1"''
      ];
    };
    ssh = {
      githubKeyPath = "/run/secrets/github-ssh-key";
    };
    flatpak = {
      packages = [
        "com.obsproject.Studio"
        "com.github.tchx84.Flatseal"
        "org.freedesktop.Platform.Gstreamer.nvenc"
      ];
    };
    discord = {
      plugins = {
        ClearURLs.enable = true;
        dearrow.enable = true;
        imageZoom.enable = true;
        normalizeMessageLinks.enable = true;
        OnePingPerDM.enable = true;
        PinDMs = {
          enable = true;
          canCollapseDmSection = true;
          pinOrder = 1;
        };
        shikiCodeblocks.enable = true;
        spotifyControls.enable = true;
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
        volumeBooster.enable = true;
        whoReacted.enable = true;
        youtubeAdblock.enable = true;
      };
    };
    zen = {
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
        ];
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
        "moz-addon-prod@7tv.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/7tv-extension/latest.xpi";
          installation_mode = "force_installed";
        };
        "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Application Distribution Platform";
    exec = "${pkgs.writeShellScript "launch-steam" ''
      id=$(${pkgs.niri}/bin/niri msg -j windows | ${pkgs.jq}/bin/jq -r '.[] | select(.app_id == "steam" and (.title | test("^notificationtoasts") | not)) | .id' | head -n 1)
      if [ -n "$id" ]; then
          ${pkgs.niri}/bin/niri msg action focus-window --id "$id"
      else
          nohup steam -system-composer "$@" > /dev/null 2>&1 &
      fi
    ''} %U";
    icon = "steam";
    terminal = false;
    categories = ["Network" "FileTransfer" "Game"];
    mimeType = ["x-scheme-handler/steam" "x-scheme-handler/steamlink"];
  };

  services.mako.enable = false;
}
