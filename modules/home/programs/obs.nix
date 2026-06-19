{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.obs;

  # For plugins distributed as nixpkgs obs-studio-plugins.
  # nixpkgs layout: lib/obs-plugins/<soName>.so, share/obs/obs-plugins/<dataName>/
  # flatpak layout: plugins/<dirName>/bin/64bit/<soName>.so, plugins/<dirName>/data/
  mkPluginNixpkgs = {
    # Directory name OBS scans (must match the .so basename for OBS to load it)
    dirName,
    # Basename of the .so inside lib/obs-plugins/ (and share/obs/obs-plugins/)
    soName ? dirName,
    pkg,
  }: let
    base = ".var/app/com.obsproject.Studio/config/obs-studio/plugins/${dirName}";
  in {
    "${base}/bin/64bit/${soName}.so".source = "${pkg}/lib/obs-plugins/${soName}.so";
    "${base}/data".source = "${pkg}/share/obs/obs-plugins/${soName}";
  };

  pipewireAudioCaptureFiles =
    lib.optionalAttrs cfg.plugins.pipewireAudioCapture.enable
    (mkPluginNixpkgs {
      dirName = "linux-pipewire-audio";
      pkg = pkgs.obs-studio-plugins.obs-pipewire-audio-capture;
    });

  backgroundRemovalFiles =
    lib.optionalAttrs cfg.plugins.backgroundRemoval.enable
    (mkPluginNixpkgs {
      dirName = "obs-backgroundremoval";
      pkg = pkgs.obs-studio-plugins.obs-backgroundremoval;
    });
in {
  options.custom = {
    programs.obs = {
      enable = lib.mkEnableOption "OBS Studio via Flatpak with plugin management";
      plugins = {
        pipewireAudioCapture = {
          enable = lib.mkEnableOption "PipeWire Audio Capture plugin";
        };
        backgroundRemoval = {
          enable = lib.mkEnableOption "Background Removal plugin";
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
      pipewireAudioCaptureFiles
      backgroundRemovalFiles
    ];
  };
}
