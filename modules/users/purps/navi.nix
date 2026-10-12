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
    # mango is the default session (greetd, hosts/navi/session.nix); niri
    # stays configured as a fallback session pickable in tuigreet (F3).
    mango.enable = true;
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
    # arrpc.enable = true;
    # discordRpc.enable = true;
    bolt.enable = true;
    bottles.enable = true;
    prismlauncher.enable = true;
    osu.enable = true;

    stremio.enable = true;
    celluloid.enable = true;
    aniCli.enable = true;
    spotify.enable = true;
    okular.enable = true;
    pinta.enable = true;
    chatterino.enable = true;
    chatterino.kickClientIdPath = osConfig.sops.secrets."chatterino7-kick-client".path;
    chatterino.kickClientSecretPath = osConfig.sops.secrets."chatterino7-kick-secret".path;
    imv.enable = true;

    rustdesk = {
      enable = true;
      serverFile = osConfig.sops.secrets."rustdesk-server".path;
      keyFile = osConfig.sops.secrets."rustdesk-key".path;
    };

    # Downstairs TCL Google TV. It sits on the 10.0.20.0/24 VLAN, reachable
    # from here but not on this L2 segment, so it must be an IP: adb's mDNS
    # discovery is multicast and does not cross the subnet boundary.
    scrcpy = {
      enable = true;
      address = "10.0.20.155:5555";
      extraArgs = [
        "--max-size=1280"
        "--video-bit-rate=8M"
      ];
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

  # Compositor-aware Steam launcher: focus an existing Steam window instead of
  # spawning a second instance (niri: by window id; mango: by focusid).
  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Application Distribution Platform";
    exec = "${pkgs.writeShellScript "launch-steam" ''
      jq=${pkgs.jq}/bin/jq
      notToast='(.title | test("^notificationtoasts") | not)'
      if [ -n "''${MANGO_INSTANCE_SIGNATURE:-}" ]; then
          id=$(${pkgs.mango}/bin/mmsg get all-clients | $jq -r ".clients[] | select(.appid == \"steam\" and $notToast) | .id" | head -n 1)
          [ -n "$id" ] && exec ${pkgs.mango}/bin/mmsg dispatch focusid "client,$id"
      elif [ -n "''${NIRI_SOCKET:-}" ]; then
          id=$(${pkgs.niri}/bin/niri msg -j windows | $jq -r ".[] | select(.app_id == \"steam\" and $notToast) | .id" | head -n 1)
          [ -n "$id" ] && exec ${pkgs.niri}/bin/niri msg action focus-window --id "$id"
      fi
      nohup env STEAM_DISABLE_BROWSER_COMPOSITOR_STEAM_HEADER=1 steam -system-composer "$@" > /dev/null 2>&1 &
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

  # ---------------------------------------------------------------------------
  # navi-specific mango layout — the same desktop as the niri block above:
  # scrolling columns that open full-width, edge-to-edge horizontally, no
  # borders/rounding, same keybinds. Super = niri's Mod.
  # ---------------------------------------------------------------------------
  custom.programs.mango = {
    inputConfig = ''
      xkb_rules_layout=us
      repeat_rate=25
      repeat_delay=600
      mouse_accel_profile=1
      mouse_accel_speed=0.0
      tap_to_click=1
      trackpad_natural_scrolling=1
    '';

    # Positions are logical (post-scale): 2560 / 1.5 = 1707, as in niri.
    # VRR stays off: games tear instead (allow_tearing below), which is what
    # gives uncapped FPS without waiting on the refresh.
    outputConfig = ''
      monitor_rule=name:^DP-1$,width:2560,height:1440,refresh:144,x:0,y:0,scale:1.5,vrr:0,primary:1
      monitor_rule=name:^DP-3$,width:2560,height:1440,refresh:144,x:1707,y:0,scale:1.5,vrr:0
      monitor_rule=name:^HDMI-A-3$,disable:1
    '';

    layoutConfig = ''
      # Every tag uses the niri-style scroller.
      tag_rule=id:*,layout_name:scroller

      # niri `open-maximized true` on every window: columns open full-width;
      # Super+F (switch_proportion_preset) toggles 1.0 <-> 0.5 like
      # maximize-column did.
      scroller_default_proportion=1.0
      scroller_default_proportion_single=1.0
      scroller_proportion_preset=0.5,1.0
      scroller_structs=0
      scroller_focus_center=0
      scroller_prefer_center=0

      # niri: gaps 6 with struts left/right -6 (edge-to-edge horizontally).
      gap_inner_horizontal=6
      gap_inner_vertical=6
      gap_outer_horizontal=0
      gap_outer_vertical=6

      # niri: focus-ring/border off, corner radius 0.
      border_px=0
      border_radius=0
      shadows=0
      blur=0

      # niri defaults: click-to-focus, no cursor warping.
      sloppy_focus=0
      warp_cursor=0

      # niri's focus-column-or-monitor-* / move-column-*-or-to-monitor-*.
      focus_cross_monitor=1
      exchange_cross_monitor=1

      # Vertical workspace switching like niri, with snappy niri-like timing.
      animations=1
      layer_animations=0
      animation_type_open=zoom
      animation_type_close=zoom
      zoom_initial_ratio=0.5
      zoom_end_ratio=0.8
      tag_animation_direction=0
      animation_duration_open=150
      animation_duration_close=150
      animation_duration_move=200
      animation_duration_tag=250
      animation_duration_focus=0
      animation_curve_open=0.16,1,0.3,1
      animation_curve_move=0.16,1,0.3,1
      animation_curve_tag=0.16,1,0.3,1
      animation_curve_close=0.16,1,0.3,1

      # Tearing (vsync off) for windows that ask for it or that a rule forces
      # (Steam games: modules/home/programs/gaming/steam.nix).
      allow_tearing=1

      # niri: hot-corners off.
      enable_hotarea=0
    '';

    # niri binds, translated. Unchanged keys:
    #   Super+Q close, Super+Shift+` quit, Super+Tab overview,
    #   Super+←/→ focus column (crosses monitors), Super+↑/↓ focus window or
    #   workspace, Super+Ctrl+←/→ focus monitor, Super+Shift+←/→ move column
    #   (crosses monitors), Super+Shift+↑/↓ move window to workspace,
    #   Super+Ctrl+Shift+arrows resize by ~5%, Super+Z float,
    #   Super+F width toggle, Super+Shift+F fullscreen.
    # No mango equivalent: Super+Shift+Z (switch focus floating<->tiling).
    keybinds = [
      "SUPER,q,killclient"
      "SUPER+SHIFT,grave,quit"
      "SUPER,Tab,toggleoverview"

      "SUPER,Left,focusdir,left"
      "SUPER,Right,focusdir,right"
      "SUPER,Up,focus_window_or_workspace,up"
      "SUPER,Down,focus_window_or_workspace,down"
      "SUPER,z,togglefloating"
      "SUPER+CTRL,Left,focusmon,left"
      "SUPER+CTRL,Right,focusmon,right"

      "SUPER+SHIFT,Left,move_client,left"
      "SUPER+SHIFT,Right,move_client,right"
      "SUPER+SHIFT,Up,tagtoleft,0"
      "SUPER+SHIFT,Down,tagtoright,0"
      # 5% of the 1707px-wide / 960px-tall logical outputs.
      "SUPER+CTRL+SHIFT,Left,resizewin,-85,+0"
      "SUPER+CTRL+SHIFT,Right,resizewin,+85,+0"
      "SUPER+CTRL+SHIFT,Up,resizewin,+0,-48"
      "SUPER+CTRL+SHIFT,Down,resizewin,+0,+48"
      "SUPER,f,switch_proportion_preset"
      "SUPER+SHIFT,f,togglefullscreen"
    ];

    # niri's built-in Super+drag move / Super+right-drag resize.
    bindsConfig = ''
      mousebind=SUPER,btn_left,moveresize,curmove
      mousebind=SUPER,btn_right,moveresize,curresize
    '';

    # niri: focus-at-startup on DP-1.
    startupCommands = ["sleep 1; mmsg dispatch focusmon,DP-1"];
  };
}
