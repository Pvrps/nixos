{
  pkgs,
  config,
  inputs,
  lib,
  osConfig,
  ...
}: let
  cfg = config.custom.programs.discord;
  fixed-vesktop = pkgs.vesktop.overrideAttrs (old: {
    postFixup = let
      libPath = with pkgs;
        lib.makeLibraryPath [
          libva
          stdenv.cc.cc.lib
        ];
    in
      (old.postFixup or "")
      + ''
        wrapProgram $out/bin/vesktop \
          --prefix LD_LIBRARY_PATH : "${libPath}" \
          --set LIBVA_DRIVER_NAME "nvidia" \
          --set NVD_BACKEND "direct" \
          --add-flags "--enable-features=VaapiVideoEncoder,VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,CanvasOopRasterization" \
          --add-flags "--disable-features=UseChromeOSDirectVideoDecoder"
      '';
  });
in {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  options.custom.programs.discord = {
    enable = lib.mkEnableOption "Discord via nixcord/vesktop";
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
      description = "Nixcord plugins configuration. Defaults to the shared household set; override per-user to diverge.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      discord.enable = false;
      vesktop = {
        enable = true;
        package = lib.mkIf (osConfig.hardware.nvidia.modesetting.enable or false) fixed-vesktop;
        useSystemVencord = false;
        settings = {
          arRPC = false;
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

    custom.programs.niri.startupCommands = lib.mkIf config.custom.programs.niri.enable [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; vesktop --start-minimized > /dev/null 2>&1"''
    ];

    custom.programs.niri.windowRulesConfig = lib.mkIf config.custom.programs.niri.enable ''
      window-rule {
          match app-id="vesktop" title="Discord Updater"
          match app-id="vesktop" title="Checking for updates..."
          open-floating true
          open-maximized false
      }
    '';
  };
}
