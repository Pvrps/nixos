{pkgs, ...}: {
  custom.programs = {
    steam.enable = true;
    discord = {
      enable = true;
      plugins = {
        ClearURLs.enable = true;
        dearrow.enable = true;
        imageZoom.enable = true;
        OnePingPerDM.enable = true;
        PinDMs = {
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
          disableVP8Codec = false;
          disableVP9Codec = false;
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
    bolt.enable = true;
    prismlauncher.enable = true;
  };

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
    categories = ["Network" "FileTransfer" "Game"];
    mimeType = ["x-scheme-handler/steam" "x-scheme-handler/steamlink"];
  };

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
