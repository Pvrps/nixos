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

  # Shaders are rewritten at build time; every rewrite is checked so an
  # upstream change fails the build instead of silently breaking playback.
  #
  # All: the shaders ship with "only run above 1.3x" (//!WHEN ... / 1.3 >).
  # A maximized 1080p window on a 1440p screen is ~1.15x once bars and
  # controls take their share, so let them run for any enlargement.
  #
  # ArtCNN (forLibmpv): WORKAROUND: ArtCNN targets gpu-next, see WORKAROUNDS.md
  prepareShader = {
    src,
    forLibmpv ? false,
  }:
    pkgs.runCommand (baseNameOf src.name) {} ''
      fail() { echo "${src.name}: $1, update prepareShader" >&2; exit 1; }

      sed -E 's#^//!WHEN OUTPUT\.w LUMA\.w / 1\.30* > OUTPUT\.h LUMA\.h / 1\.30* > \*$#//!WHEN OUTPUT.w LUMA.w / 1.0 > OUTPUT.h LUMA.h / 1.0 > *#' ${src} > when.glsl
      grep -q '^//!WHEN.*1\.3' when.glsl && fail "unexpected //!WHEN lines"
      grep -q '^//!WHEN OUTPUT.w LUMA.w / 1.0 >' when.glsl || fail "no //!WHEN lines rewritten"

      ${
        if forLibmpv
        then ''
          # 1. Drop the f16 #extension lines: vo_gpu inserts user code after
          #    its own header, where #extension is a compile error. The
          #    shader's #else branch then uses plain float (full precision).
          # 2. The final Depth-To-Space pass hooks LUMA with 4 components,
          #    which vo_gpu rejects (max 1); it only writes .x anyway.
          grep -v '^#extension GL_EXT_shader_explicit_arithmetic_types_float16' when.glsl \
            | awk '/^\/\/!DESC/ { dts = /Depth-To-Space/ } dts && /^\/\/!COMPONENTS 4$/ { print "//!COMPONENTS 1"; next } { print }' \
            > $out
          grep -q '^#extension' $out && fail "#extension lines left"
          grep -A8 'Depth-To-Space' $out | grep -q '^//!COMPONENTS 1$' || fail "Depth-To-Space pass not adapted"
        ''
        else "cp when.glsl $out"
      }
    '';

  # MAINTENANCE: see MAINTENANCE.md
  fsrcnnx = prepareShader {
    src = pkgs.fetchurl {
      url = "https://github.com/igv/FSRCNN-TensorFlow/releases/download/1.1/FSRCNNX_x2_16-0-4-1.glsl";
      hash = "sha256-1aJKJx5dmj9/egU7FQxGCkTCWzz393CFfVfMOi4cmWU=";
    };
  };

  # ArtCNN C4F32 luma doublers (anime): neutral, DS (denoise + sharpen),
  # DN (denoise + soften). MAINTENANCE: see MAINTENANCE.md
  artcnnVersion = "1.6.2";
  artcnn = variant: hash:
    prepareShader {
      src = pkgs.fetchurl {
        url = "https://github.com/Artoriuz/ArtCNN/releases/download/v${artcnnVersion}/ArtCNN_${variant}.glsl";
        inherit hash;
      };
      forLibmpv = true;
    };
  artcnnNeutral = artcnn "C4F32" "sha256-93O85s9f5+Xl1Zmmle3UDfXNeiDD0IxNFk0HWR1b6tM=";
  artcnnDS = artcnn "C4F32_DS" "sha256-oEycum+7jm25I51hhIOQIIrt+ONI7xFuEhdMgD0iB34=";
  artcnnDN = artcnn "C4F32_DN" "sha256-a1Gm99dYJslJLD94teYKz/okpxko4tR8SjKUI5IqFDw=";

  setShader = key: label: shader: ''${key} no-osd change-list glsl-shaders set "${shader}"; show-text "${label}"'';

  mpvConfDir = "${config.xdg.configHome}/mpv";

  # "Play in Celluloid" for YouTube: a Violentmonkey userscript adds a player
  # button that asks this localhost launcher to open the video at the current
  # time; when Celluloid closes the launcher answers with the position and
  # the tab seeks there. The launcher also serves the userscript, so
  # Violentmonkey installs and updates it from
  # http://127.0.0.1:<port>/youtube-celluloid.user.js.
  inherit (cfg.openFromBrowser) port;
  userscript = pkgs.replaceVars ./_celluloid/youtube-celluloid.user.js {
    port = toString port;
    # Violentmonkey only updates to a higher version: bump on every edit.
    version = "1.1";
  };
  launcher = pkgs.writers.writePython3Bin "celluloid-launcher" {
    flakeIgnore = ["E501"];
  } (builtins.readFile ./_celluloid/launcher.py);
in {
  options.custom.programs.celluloid = {
    enable = lib.mkEnableOption "Celluloid media player";

    package = lib.mkOption {
      type = lib.types.package;
      default = celluloid;
      readOnly = true;
      description = "The Celluloid build used everywhere (launcher, YouTube button, ani-cli).";
    };

    upscale.enable = lib.mkEnableOption ''
      GPU upscaling for every mpv-based player that reads ~/.config/mpv:
      FSRCNNX x2 + deband by default, ArtCNN via the "anime" profile
      (used by ani-cli). Ctrl+1/2/3 pick ArtCNN neutral/DS/DN, Ctrl+9
      FSRCNNX, Ctrl+0 turns shaders off'';

    openFromBrowser = {
      enable = lib.mkEnableOption ''
        a "Play in Celluloid" button on YouTube (Violentmonkey userscript +
        localhost launcher) that starts at the tab's timestamp and seeks the
        tab to where playback stopped once Celluloid closes'';

      port = lib.mkOption {
        type = lib.types.port;
        default = 47810;
        description = "127.0.0.1 port of the launcher the userscript talks to.";
      };
    };
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
        # Runs whenever the video is shown larger than its own resolution.
        glsl-shaders=${fsrcnnx}

        [anime]
        profile-desc=ArtCNN C4F32 DS
        glsl-shaders=${artcnnDS}
      '';

      xdg.configFile."mpv/input.conf".text = lib.concatStringsSep "\n" [
        (setShader "CTRL+1" "ArtCNN" artcnnNeutral)
        (setShader "CTRL+2" "ArtCNN DS (denoise + sharpen)" artcnnDS)
        (setShader "CTRL+3" "ArtCNN DN (denoise + soften)" artcnnDN)
        (setShader "CTRL+9" "FSRCNNX x2" fsrcnnx)
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
      systemd.user.services.celluloid-launcher = {
        Unit = {
          Description = "Celluloid launcher for the YouTube userscript";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = lib.getExe launcher;
          Environment = [
            "CELLULOID=${lib.getExe cfg.package}"
            "USERSCRIPT=${userscript}"
            "PORT=${toString port}"
          ];
          Restart = "on-failure";
          # Restarting the launcher (e.g. on switch) must not close players.
          KillMode = "process";
        };
        Install.WantedBy = ["graphical-session.target"];
      };
    })
  ]);
}
