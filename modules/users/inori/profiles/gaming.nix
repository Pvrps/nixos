{pkgs, ...}: {
  custom.programs = {
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
