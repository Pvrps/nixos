{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: let
  cfg = config.custom.programs.osu;

  # WORKAROUND: no Linux audio latency setting in osu!, see WORKAROUNDS.md
  osu = pkgs.symlinkJoin {
    name = "osu-lazer-bin-low-latency";
    paths = [pkgs.osu-lazer-bin];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      rm "$out/bin/osu!"
      makeWrapper "${pkgs.osu-lazer-bin}/bin/osu!" "$out/bin/osu!" \
        --set-default OSU_TEMP_TESTING_BASS_CONFIG_DEV_PERIOD -256
    '';
  };

  # shared-mime-info entry registering osu!'s custom file extensions so XDG
  # file managers / portals dispatch .osk, .osz, .olz and .osr files to the
  # correct MIME type. osu-lazer-bin's desktop entry already advertises these
  # types as supported; this just teaches the system mime DB the globs.
  osu-mime-info = pkgs.writeText "osu-mime-info.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-osu-skin-archive">
        <comment>osu! skin archive</comment>
        <glob pattern="*.osk"/>
      </mime-type>
      <mime-type type="application/x-osu-beatmap-archive">
        <comment>osu! beatmap archive</comment>
        <glob pattern="*.osz"/>
        <glob pattern="*.olz"/>
      </mime-type>
      <mime-type type="application/x-osu-replay">
        <comment>osu! replay</comment>
        <glob pattern="*.osr"/>
      </mime-type>
    </mime-info>
  '';
in {
  options.custom.programs.osu.enable = lib.mkEnableOption "osu!lazer (AppImage build with score submission and multiplayer)";

  config = lib.mkIf cfg.enable {
    home.packages = [osu];

    # Present immediately (tear) instead of waiting for the next vblank, with
    # VRR while visible: same "G-Sync + V-Sync off" setup as Steam games
    # (see steam.nix). allow-tearing needs the urayde/niri fork.
    custom.programs.niri.windowRulesConfig = lib.mkIf config.custom.programs.niri.enable (
      ''
        window-rule {
            match app-id=r#"^osu!$"#
            variable-refresh-rate true
        }
      ''
      + lib.optionalString (osConfig.custom.niri.tearingFork.enable or false) ''

        window-rule {
            match app-id=r#"^osu!$"#
            allow-tearing true
        }
      ''
    );

    custom.programs.mango.windowRulesConfig = lib.mkIf config.custom.programs.mango.enable ''
      window_rule=force_tearing:1,app_id:^osu!$
    '';

    # Drop the custom mime-info into the user mime DB so .osk etc. resolve to
    # the right MIME type. The freedesktop spec requires the package file to
    # live under $XDG_DATA_HOME/mime/packages/; update-mime-database then merges
    # it into the cached globs/globs2 lookup tables.
    xdg.dataFile."mime/packages/osu.xml".source = osu-mime-info;

    # Rebuild the user mime cache after the xml is in place. home-manager's
    # writeBoundary is the commit point for its own filesystem writes, so
    # running after it guarantees osu.xml is present on disk.
    home.activation.rebuild-osu-mime-db = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.shared-mime-info}/bin/update-mime-database ''${XDG_DATA_HOME:-$HOME/.local/share}/mime
    '';

    # The upstream osu!.desktop from osu-lazer-bin declares these MIME types
    # but its file ID contains '!' which violates the desktop-entry-spec ID
    # regex, so some picky XDG implementations refuse to resolve it as a
    # default app. Ship a spec-compliant alias with the same Exec and MIME
    # support, and use it as the default for the osu! archive types.
    # NoDisplay hides it from the launcher so only "osu!" shows up.
    xdg.desktopEntries.osu-lazer = {
      name = "osu!lazer";
      genericName = "Rhythm Game";
      exec = "env SDL_VIDEODRIVER=wayland osu! %u";
      icon = "osu";
      terminal = false;
      categories = ["Game"];
      mimeType = [
        "application/x-osu-beatmap-archive"
        "application/x-osu-skin-archive"
        "application/x-osu-beatmap"
        "application/x-osu-storyboard"
        "application/x-osu-replay"
        "x-scheme-handler/osu"
      ];
      startupNotify = true;
      settings = {
        StartupWMClass = "osu!";
        SingleMainWindow = "true";
        NoDisplay = "true";
      };
    };

    xdg.mimeApps.defaultApplications = {
      "application/x-osu-skin-archive" = "osu-lazer.desktop";
      "application/x-osu-beatmap-archive" = "osu-lazer.desktop";
      "application/x-osu-replay" = "osu-lazer.desktop";
    };
  };
}
