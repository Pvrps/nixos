{
  pkgs,
  osConfig,
  ...
}: let
  mavenExt = import ./vscode-maven.nix {inherit pkgs;};
  javaDebugExt = import ./vscode-java-debug.nix {inherit pkgs;};
in {
  imports = [
    ./general.nix
  ];

  custom.theme.enable = true;

  home = {
    packages = [pkgs.trash-cli];

    persistence."/persist" = {
      hideMounts = true;
      directories = [
        ".local"
        ".config"
        ".var"
        ".gnupg"
        ".pki"
        ".ssh"
        ".putty"
        "Downloads"
        "Pictures"
        "Videos"
        "Development"
        "Documents"
        # GPU shader caches — avoid recompiling shaders every boot.
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

  custom.programs = {
    gnomeKeyring.enable = true;

    noctalia.enable = true;
    niri.enable = true;
    foot = {
      enable = true;
      pad = "8x8";
    };
    ghostty.enable = false;
    termfilepickers.enable = false;

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
        "*" = {
          installation_mode = "blocked";
        };
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

    zed = {
      enable = false;
      extensions = [
        "nix"
        "java"
        "svelte"
        "xml"
        "dockerfile"
        "nginx"
        "graphql"
        "sql"
        "jsonnet"
        "just"
        "toml"
      ];
    };

    vscode = {
      enable = true;
      javaFormatterConfig = files/eclipse-formatter.xml;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        davidanson.vscode-markdownlint
        naumovs.color-highlight
        esbenp.prettier-vscode
        vscjava.vscode-java-pack
        redhat.java
        javaDebugExt
        vscjava.vscode-java-test
        mavenExt
        vscjava.vscode-java-dependency
        vscjava.vscode-gradle
        oderwat.indent-rainbow
      ];
      userSettings = {
        "editor.formatOnSave" = true;
        "editor.formatOnSaveMode" = "modificationsIfAvailable";
        "java.cleanup.actions" = [
          "qualifyStaticMembers"
          "addOverride"
          "addDeprecated"
          "stringConcatToTextBlock"
          "invertEquals"
          "addFinalModifier"
          "lambdaExpressionFromAnonymousClass"
          "lambdaExpression"
          "switchExpression"
          "tryWithResource"
          "renameFileToType"
          "organizeImports"
          "renameUnusedLocalVariables"
          "useSwitchForInstanceofPattern"
        ];
        "java.format.settings.url" = "/home/purps/.config/Code/User/eclipse-formatter.xml";
        "redhat.telemetry.enabled" = false;
        "window.restoreWindows" = "none";
        "git.confirmSync" = false;
        "[java]" = {
          "editor.defaultFormatter" = "redhat.java";
          "editor.formatOnSave" = true;
        };
        "editor.codeActionsOnSave" = {
          "source.generate.finalModifiers" = "explicit";
          "source.organizeImports" = "explicit";
        };
        "java.configuration.runtimes" = [
          {
            name = "JavaSE-1.8";
            path = "${pkgs.zulu8}";
          }
          {
            name = "JavaSE-11";
            path = "${pkgs.zulu11}";
          }
          {
            name = "JavaSE-17";
            path = "${pkgs.zulu17}";
          }
          {
            name = "JavaSE-21";
            path = "${pkgs.zulu21}";
            default = true;
          }
        ];
        "maven.executable.path" = "${pkgs.maven}/bin/mvn";
      };
    };

    opencode = {
      enable = true;
      context7 = {
        enable = true;
        apiKeyPath = osConfig.sops.secrets."context7-api-key".path;
      };
      claudeAuth.enable = true;
      mcp-nixos.enable = true;
    };

    java.enable = true;

    steam = {
      enable = true;
      millenniumPlugins = {
        extendium = {
          url = "https://github.com/BossSloth/Extendium/releases/download/v1.1.1/Extendium-plugin-1.1.1.zip";
          sha256 = "0dg7q27ppzri6vqk24s1v6d6q8d0iicw3igdqc55pc8g050v1pfx";
        };
        achievement-groups = {
          url = "https://github.com/BossSloth/SteamHunter-plugin/releases/download/v2.0.2/Achievement-Groups-plugin-2.0.2.zip";
          sha256 = "18g921w6idswwvbha9dyszki60pv1pvhlzsi817ddps8pifhwpwj";
        };
      };
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
    discord-rpc-noctalia.enable = true;
    bolt.enable = true;
    prismlauncher.enable = true;
    osu.enable = true;

    stremio.enable = true;
    clapper.enable = true;
    spotify.enable = true;
    okular.enable = true;
    pinta.enable = true;
    chatterino.enable = true;
    imv.enable = true;

    linux-wallpaperengine.enable = false;
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
        pipewireAudioCapture.enable = true;
        backgroundRemoval.enable = true;
      };
    };

    easyeffects = {
      enable = true;
      preset = "blue_yeti";
      presetSource = "/persist/etc/nixos/modules/users/purps/files/blue_yeti.json";
    };
    openrgb.enable = true;
    liquidctl = {
      enable = true;
      lcdImage = ./assets/master-sword.gif;
      brightness = 100;
      orientation = 270;
    };

    ssh = {
      extraHosts = {
        "windwaker" = {
          HostName = "windwaker";
          User = "purps";
          IdentityFile = osConfig.sops.secrets."windwaker-purps-key".path;
        };
        "ciela" = {
          HostName = "ciela";
          User = "purps";
          IdentityFile = osConfig.sops.secrets."ciela-purps-key".path;
        };
        "mickey" = {
          HostName = "mickey";
          User = "purps";
          IdentityFile = osConfig.sops.secrets."mickey-purps-key".path;
        };
      };
    };
  };

  custom.scripts = {
    capture = {
      screenshot.enable = true;
      recording.enable = true;
      edit.enable = true;
      ocr.enable = true;
    };
    hist-clean.enable = true;
    gitingest.enable = true;
    ports-summary.enable = true;
    dir2clip.enable = true;
    "2m4b".enable = true;
    abd.enable = true;
    micsave = {
      enable = true;
      presetGitPath = "/persist/etc/nixos/modules/users/purps/files/blue_yeti.json";
    };
  };

  # niri-aware Steam launcher: focus an existing Steam window instead of
  # spawning a second instance.
  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Application Distribution Platform";
    exec = "${pkgs.writeShellScript "launch-steam" ''
      id=$(${pkgs.niri}/bin/niri msg -j windows | ${pkgs.jq}/bin/jq -r '.[] | select(.app_id == "steam" and (.title | test("^notificationtoasts") | not)) | .id' | head -n 1)
      if [ -n "$id" ]; then
          ${pkgs.niri}/bin/niri msg action focus-window --id "$id"
      else
          nohup env STEAM_DISABLE_BROWSER_COMPOSITOR_STEAM_HEADER=1 steam -system-composer "$@" > /dev/null 2>&1 &
      fi
    ''} %U";
    icon = "steam";
    terminal = false;
    categories = [
      "Network"
      "FileTransfer"
      "Game"
    ];
    mimeType = [
      "x-scheme-handler/steam"
      "x-scheme-handler/steamlink"
    ];
  };

  # ---------------------------------------------------------------------------
  # navi-specific niri layout (outputs/inputs/binds).
  # ---------------------------------------------------------------------------
  custom.programs.noctalia.primaryMonitor = "DP-1";
  custom.programs.niri = {
    xwaylandDisplay = ":11";

    inputConfig = ''
      input {
          keyboard {
              xkb {

              }
          }
          mouse {
              accel-profile "flat"
              accel-speed 0
          }
          touchpad {
              tap
              natural-scroll
          }
      }
    '';

    outputConfig = ''
      output "DP-1" {
          mode "2560x1440@144"
          position x=0 y=0
          scale 1.5
          variable-refresh-rate on-demand=true
          focus-at-startup
      }

      output "DP-3" {
          mode "2560x1440@144"
          position x=1707 y=0
          scale 1.5
          variable-refresh-rate on-demand=true
      }

      output "HDMI-A-3" {
          off
      }
    '';

    layoutConfig = ''
      layout {
          gaps 6
          default-column-width { proportion 0.5; }
          focus-ring {
              off
          }
          border {
              off
          }
          struts {
              left -6
              right -6
          }
      }
    '';

    windowRulesConfig = ''
      window-rule {
          open-maximized true
      }

      window-rule {
          geometry-corner-radius 0
          clip-to-geometry true
      }
    '';

    bindsConfig = ''
      Mod+Q { close-window; }
      Mod+Shift+Grave { quit; }
      Mod+Tab { toggle-overview; }

      Mod+Left  { focus-column-or-monitor-left; }
      Mod+Right { focus-column-or-monitor-right; }
      Mod+Up    { focus-window-or-workspace-up; }
      Mod+Down  { focus-window-or-workspace-down; }
      Mod+Z     { toggle-window-floating; }
      Mod+Ctrl+Left  { focus-monitor-left; }
      Mod+Ctrl+Right { focus-monitor-right; }

      Mod+Shift+Left  { move-column-left-or-to-monitor-left; }
      Mod+Shift+Right { move-column-right-or-to-monitor-right; }
      Mod+Shift+Up    { move-window-up-or-to-workspace-up; }
      Mod+Shift+Down  { move-window-down-or-to-workspace-down; }
      Mod+Ctrl+Shift+Left  { set-column-width "-5%"; }
      Mod+Ctrl+Shift+Right { set-column-width "+5%"; }
      Mod+Ctrl+Shift+Up    { set-window-height "-5%"; }
      Mod+Ctrl+Shift+Down  { set-window-height "+5%"; }
      Mod+Shift+Z { switch-focus-between-floating-and-tiling; }
      Mod+F { maximize-column; }
      Mod+Shift+F { fullscreen-window; }
    '';

    gesturesConfig = ''
      gestures {
          hot-corners {
              off
          }
      }
    '';

    extraConfig = ''
      screenshot-path "~/Pictures/Screenshots/%Y-%m-%d-%H-%M-%S.png"

      // Runtime-managed window rules (written/cleared by `just run` in the osrs
      // project). Optional so a missing file is a warning, not an error; niri
      // live-reloads when it appears, changes, or is removed.
      include optional=true "~/.config/niri/runtime-rules.kdl"
    '';
  };
}
