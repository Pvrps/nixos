{
  pkgs,
  osConfig,
  ...
}: {
  imports = [
    ./general.nix
  ];

  custom.theme.enable = true;
  custom.profiles.desktop.enable = true;

  # On top of the desktop-profile baseline.
  home.persistence."/persist".directories = [
    ".ssh"
    ".putty"
    "Development"
  ];

  custom.programs = {
    gnomeKeyring.enable = true;

    noctalia.enable = true;
    niri.enable = true;
    foot = {
      enable = true;
      pad = "8x8";
    };

    thunar.enable = true;

    zen = {
      enable = true;
      homepage = "https://homepage.windwaker.ca/";
      settings = {
        # Hardware video decoding — VA-API via nvidia-vaapi-driver.
        # force-enabled bypasses gfxInfo blocklist which blocks HW decode on NVIDIA.
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "gfx.webrender.all" = true;
        # Force DMABuf WebGL — blocklisted by gfxInfo on NVIDIA but works fine.
        "webgl.force-enabled" = true;
        "webgl.disable-fail-if-major-performance-caveat" = true;
        # Use Vulkan backend for WebRender — bypasses thread-unsafe OpenGL issue on NVIDIA.
        # Fixes CANVAS_RENDERER_THREAD being blocked by FEATURE_FAILURE_THREAD_UNSAFE_GL.
        "gfx.webrender.compositor.force-enabled" = true;
        "gfx.canvas.accelerated.force-enabled" = true;
      };
      extraExtensions = {
        "@windscribeff" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/windscribe/latest.xpi";
          installation_mode = "force_installed";
        };
        "{c84d89d9-a826-4015-957b-affebd9eb603}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/mal-sync/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };

    vscode = {
      enable = true;
      javaFormatterConfig = ./files/eclipse-formatter.xml;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        davidanson.vscode-markdownlint
        naumovs.color-highlight
        esbenp.prettier-vscode
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
        "editor.codeActionsOnSave" = {
          "source.generate.finalModifiers" = "explicit";
          "source.organizeImports" = "explicit";
        };
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

    devenv.enable = true;

    steam.enable = true;
    discord.enable = true;
    arrpc.enable = true;
    discordRpc.enable = true;
    discordRpcNoctalia.enable = true;
    bolt.enable = true;
    prismlauncher.enable = true;
    osu.enable = true;

    stremio.enable = true;
    clapper.enable = true;
    aniCli.enable = true;
    spotify.enable = true;
    okular.enable = true;
    pinta.enable = true;
    chatterino.enable = true;
    imv.enable = true;

    rustdesk = {
      enable = true;
      serverFile = osConfig.sops.secrets."rustdesk-server".path;
      keyFile = osConfig.sops.secrets."rustdesk-key".path;
    };

    flatpak = {
      enable = true;
      packages = [
        "com.github.tchx84.Flatseal"
        "org.vinegarhq.Sober"
      ];
    };

    obs = {
      enable = true;
      plugins = {
        pipewireAudioCapture.enable = true;
        backgroundRemoval.enable = false;
      };
    };

    easyeffects = {
      enable = true;
      preset = "blue_yeti";
      presetSource = "/persist/etc/nixos/modules/users/purps/files/blue_yeti.json";
    };
    openrgb.enable = true;

    # Receives ciela's mic stream as a "ciela-inori-mic" PipeWire source node,
    # which OBS's PipeWire Audio Capture plugin can pick up as an independent
    # audio source.
    micStream = {
      enable = true;
      mode = "receiver";
      nodeName = "ciela-inori-mic";
      nodeDescription = "Ciela (Inori) Mic";
    };
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
    histClean.enable = true;
    gitingest.enable = true;
    portsSummary.enable = true;
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
