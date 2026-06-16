{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.obs;

  mkPlugin = {
    name,
    src,
  }: let
    extracted = pkgs.runCommand "obs-plugin-${name}" {} ''
      ${pkgs.dpkg}/bin/dpkg-deb -x ${src} $out
    '';
    base = ".var/app/com.obsproject.Studio/config/obs-studio/plugins/${name}";
    # Debian multiarch triplet for the .deb's lib layout (e.g. x86_64-linux-gnu).
    debianMultiarch = "${pkgs.stdenv.hostPlatform.parsed.cpu.name}-linux-gnu";
  in {
    "${base}/bin/64bit/${name}.so".source = "${extracted}/usr/lib/${debianMultiarch}/obs-plugins/${name}.so";
    # Map the entire data directory instead of just locale, as modern plugins have UI assets
    "${base}/data".source = "${extracted}/usr/share/obs/obs-plugins/${name}";
  };

  # For plugins distributed as flatpak tarballs (layout: <name>/bin/64bit/<name>.so and <name>/data/)
  # The plugin dir name must match the .so name for OBS to load it.
  mkPluginFlatpakTarball = {
    name,
    src,
  }: let
    extracted = pkgs.runCommand "obs-plugin-${name}" {} ''
      mkdir -p $out
      ${pkgs.gnutar}/bin/tar -xzf ${src} -C $out --strip-components=1
    '';
    base = ".var/app/com.obsproject.Studio/config/obs-studio/plugins/${name}";
  in {
    "${base}/bin/64bit/${name}.so".source = "${extracted}/bin/64bit/${name}.so";
    "${base}/data".source = "${extracted}/data";
  };

  aitumStreamSuiteFiles =
    lib.optionalAttrs cfg.plugins.aitumStreamSuite.enable
    (mkPlugin {
      name = "aitum-stream-suite";
      src = pkgs.fetchurl {
        url = "https://github.com/Aitum/obs-aitum-stream-suite/releases/download/${cfg.plugins.aitumStreamSuite.version}/aitum-stream-suite-linux-gnu.deb";
        inherit (cfg.plugins.aitumStreamSuite) hash;
      };
    });
  pipewireAudioCaptureFiles =
    lib.optionalAttrs cfg.plugins.pipewireAudioCapture.enable
    (mkPluginFlatpakTarball {
      # OBS loads plugins by scanning subdirs of plugins/; the dir name must match the .so name
      name = "linux-pipewire-audio";
      src = pkgs.fetchurl {
        url = "https://github.com/dimtpap/obs-pipewire-audio-capture/releases/download/${cfg.plugins.pipewireAudioCapture.version}/linux-pipewire-audio-${cfg.plugins.pipewireAudioCapture.version}-flatpak-30.tar.gz";
        inherit (cfg.plugins.pipewireAudioCapture) hash;
      };
    });
in {
  options.custom = {
    programs.obs = {
      enable = lib.mkEnableOption "OBS Studio via Flatpak with plugin management";
      plugins = {
        aitumStreamSuite = {
          enable = lib.mkEnableOption "Aitum Stream Suite plugin";
          version = lib.mkOption {
            type = lib.types.str;
            default = "1.1.0";
            description = "GitHub release tag for aitum-stream-suite";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            description = "SHA256 hash of the .deb release asset";
          };
        };
        pipewireAudioCapture = {
          enable = lib.mkEnableOption "PipeWire Audio Capture";
          version = lib.mkOption {
            type = lib.types.str;
            default = "1.2.1";
            description = "GitHub release tag for pipewire-audio-capture";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            description = "SHA256 hash of the flatpak tarball release asset";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.obs requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.programs.flatpak.packages = lib.mkAfter ["com.obsproject.Studio"];

    # Fix audio crackling when opening OBS by increasing PulseAudio latency
    home.activation.obsPulseLatency = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.flatpak}/bin/flatpak override --user --env=PULSE_LATENCY_MSEC=60 com.obsproject.Studio
    '';

    home.file = lib.mkMerge [
      aitumStreamSuiteFiles
      pipewireAudioCaptureFiles
    ];
  };
}
