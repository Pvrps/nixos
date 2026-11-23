{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.celluloid;

  # WORKAROUND: GTK hands Celluloid a GLES context on NVIDIA, see WORKAROUNDS.md
  celluloid = pkgs.celluloid.overrideAttrs (old: {
    preFixup =
      (old.preFixup or "")
      + ''
        gappsWrapperArgs+=(--set-default GDK_DISABLE gles-api)
      '';
  });

  # MAINTENANCE: see MAINTENANCE.md
  fsrcnnx = pkgs.fetchurl {
    url = "https://github.com/igv/FSRCNN-TensorFlow/releases/download/1.1/FSRCNNX_x2_16-0-4-1.glsl";
    hash = "sha256-1aJKJx5dmj9/egU7FQxGCkTCWzz393CFfVfMOi4cmWU=";
  };

  # Anime4K presets (upstream GLSL_Instructions_Advanced, "HQ" variants).
  a4k = name: "${pkgs.anime4k}/Anime4K_${name}.glsl";
  shaderList = names: lib.concatMapStringsSep ":" a4k names;
  anime4k = {
    "Mode A" = shaderList ["Clamp_Highlights" "Restore_CNN_VL" "Upscale_CNN_x2_VL" "AutoDownscalePre_x2" "AutoDownscalePre_x4" "Upscale_CNN_x2_M"];
    "Mode B" = shaderList ["Clamp_Highlights" "Restore_CNN_Soft_VL" "Upscale_CNN_x2_VL" "AutoDownscalePre_x2" "AutoDownscalePre_x4" "Upscale_CNN_x2_M"];
    "Mode C" = shaderList ["Clamp_Highlights" "Upscale_Denoise_CNN_x2_VL" "AutoDownscalePre_x2" "AutoDownscalePre_x4" "Upscale_CNN_x2_M"];
    "Mode A+A" = shaderList ["Clamp_Highlights" "Restore_CNN_VL" "Upscale_CNN_x2_VL" "Restore_CNN_M" "AutoDownscalePre_x2" "AutoDownscalePre_x4" "Upscale_CNN_x2_M"];
    "Mode B+B" = shaderList ["Clamp_Highlights" "Restore_CNN_Soft_VL" "Upscale_CNN_x2_VL" "AutoDownscalePre_x2" "AutoDownscalePre_x4" "Restore_CNN_Soft_M" "Upscale_CNN_x2_M"];
    "Mode C+A" = shaderList ["Clamp_Highlights" "Upscale_Denoise_CNN_x2_VL" "AutoDownscalePre_x2" "AutoDownscalePre_x4" "Restore_CNN_M" "Upscale_CNN_x2_M"];
  };

  setShaders = key: label: shaders: ''${key} no-osd change-list glsl-shaders set "${shaders}"; show-text "${label}"'';

  mpvConfDir = "${config.xdg.configHome}/mpv";
in {
  options.custom.programs.celluloid = {
    enable = lib.mkEnableOption "Celluloid media player";

    package = lib.mkOption {
      type = lib.types.package;
      default = celluloid;
      readOnly = true;
      description = "The Celluloid build used everywhere (launcher, ff2mpv, ani-cli).";
    };

    upscale.enable = lib.mkEnableOption ''
      GPU upscaling for every mpv-based player that reads ~/.config/mpv:
      FSRCNNX x2 + deband by default, Anime4K via the "anime" profile
      (used by ani-cli). Ctrl+1..6 pick an Anime4K mode, Ctrl+9 FSRCNNX,
      Ctrl+0 turns shaders off'';

    openFromBrowser.enable = lib.mkEnableOption ''
      the ff2mpv button in Zen ("Play in MPV"), opening the page's video
      in Celluloid'';
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Celluloid's wrapper already puts yt-dlp on its PATH, so it plays
      # YouTube (and other yt-dlp supported) URLs directly.
      home.packages = [cfg.package];

      xdg.mimeApps.defaultApplications = {
        "video/mp4" = "io.github.celluloid_player.Celluloid.desktop";
        "video/webm" = "io.github.celluloid_player.Celluloid.desktop";
        "video/x-matroska" = "io.github.celluloid_player.Celluloid.desktop";
        "video/quicktime" = "io.github.celluloid_player.Celluloid.desktop";
      };
    }

    (lib.mkIf cfg.upscale.enable {
      # Plain files instead of programs.mpv: Celluloid is the only player, so
      # the standalone mpv binary isn't installed. Shaders use absolute store
      # paths because Celluloid points mpv's config-dir (~~) at its own dir.
      xdg.configFile."mpv/mpv.conf".text = ''
        profile=high-quality
        hwdec=auto-safe
        deband=yes
        ytdl-format=bestvideo[height<=?2160]+bestaudio/best
        # Only kicks in when upscaling by more than 1.3x (e.g. 1080p -> 1440p).
        glsl-shaders=${fsrcnnx}

        [anime]
        profile-desc=Anime4K Mode A (HQ)
        glsl-shaders=${anime4k."Mode A"}
      '';

      xdg.configFile."mpv/input.conf".text = lib.concatStringsSep "\n" [
        (setShaders "CTRL+1" "Anime4K: Mode A (HQ)" anime4k."Mode A")
        (setShaders "CTRL+2" "Anime4K: Mode B (HQ)" anime4k."Mode B")
        (setShaders "CTRL+3" "Anime4K: Mode C (HQ)" anime4k."Mode C")
        (setShaders "CTRL+4" "Anime4K: Mode A+A (HQ)" anime4k."Mode A+A")
        (setShaders "CTRL+5" "Anime4K: Mode B+B (HQ)" anime4k."Mode B+B")
        (setShaders "CTRL+6" "Anime4K: Mode C+A (HQ)" anime4k."Mode C+A")
        (setShaders "CTRL+9" "FSRCNNX x2" "${fsrcnnx}")
        ''CTRL+0 no-osd change-list glsl-shaders clr ""; show-text "Shaders off"''
        ""
      ];

      # Celluloid ignores ~/.config/mpv unless told to load it.
      dconf.settings."io/github/celluloid-player/celluloid" = {
        mpv-config-enable = true;
        mpv-config-file = "file://${mpvConfDir}/mpv.conf";
        mpv-input-config-enable = true;
        mpv-input-config-file = "file://${mpvConfDir}/input.conf";
      };
    })

    (lib.mkIf cfg.openFromBrowser.enable {
      # ff2mpv-rust is the native host; it launches player_command with
      # player_args, then the URL. "--" keeps a page URL from being parsed
      # as an option.
      xdg.configFile."ff2mpv-rust.json".text = builtins.toJSON {
        player_command = lib.getExe cfg.package;
        player_args = ["--"];
      };

      programs.zen-browser.nativeMessagingHosts = [pkgs.ff2mpv-rust];

      custom.programs.zen.extraExtensions."ff2mpv@yossarian.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ff2mpv/latest.xpi";
        installation_mode = "force_installed";
      };
    })
  ]);
}
