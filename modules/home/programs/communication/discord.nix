{
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.custom.programs.discord;

  autostartCommand = {
    discord = "discord --start-minimized";
    vesktop = "vesktop --start-minimized";
  };
in {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  options.custom.programs.discord = {
    enable = lib.mkEnableOption "Discord and Vesktop via nixcord/vencord";
    autostart = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["discord" "vesktop"]);
      default = "discord";
      description = ''
        Client launched (minimized) at niri startup, or null for none. Both
        clients are always installed; Vesktop is the one with per-application
        stream audio (venmic/PipeWire).
      '';
    };
    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      # Shared household plugin set. Setting this option in a user file
      # replaces the whole set — per-user divergence is one override away.
      default = {
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
        typingTweaks.enable = true;
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
      description = "Nixcord plugins configuration. Defaults to the shared household set; override per-user to diverge.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      discord = {
        vencord.enable = true;
        settings = {
          arRPC = true;
        };
      };
      # Installed alongside Discord: the official client only streams system
      # audio on Linux, Vesktop can stream a single app's audio via venmic.
      # Both share `config` below (same Vencord plugins). Both run an arRPC
      # server on the same ports, so only the first one started gets Rich
      # Presence if they run at the same time.
      vesktop = {
        enable = true;
        # Managed settings.json is rewritten on each activation; anything not
        # listed here falls back to Vesktop's defaults.
        settings = {
          arRPC = true;
          tray = true;
          minimizeToTray = true;
          # The niri splash rule below matches title "Vesktop"; keep the
          # splash on and the static title off so the main window never
          # opens with that title.
          enableSplashScreen = true;
          staticTitle = false;
        };
      };

      config = {
        useQuickCss = true;
        frameless = true;
        themeLinks = [
        ];
        plugins =
          cfg.plugins
          // {
            webRichPresence.enable = true;
            volumeBooster.enable = true;
          };
      };
    };

    custom.programs.niri.startupCommands = lib.mkIf (config.custom.programs.niri.enable && cfg.autostart != null) [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; ${autostartCommand.${cfg.autostart}} > /dev/null 2>&1"''
    ];

    # Rules for both clients, since either may be launched at any time.
    custom.programs.niri.windowRulesConfig = lib.mkIf config.custom.programs.niri.enable ''
      window-rule {
          match app-id="discord" title="Discord Updater"
          match app-id="discord" title="Checking for updates..."
          match app-id=r#"(?i)^vesktop$"# title=r#"^Vesktop$"#
          open-floating true
          open-maximized false
      }
    '';
  };
}
