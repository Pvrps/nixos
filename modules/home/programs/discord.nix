{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.custom.programs.discord;
  # fixed-equibop = (pkgs.equibop.override {inherit (pkgs) electron;})
  #   .overrideAttrs (old: {
  #   postFixup = let
  #     libPath = with pkgs;
  #       lib.makeLibraryPath [
  #         libva
  #         stdenv.cc.cc.lib
  #       ];
  #   in
  #     (old.postFixup or "")
  #     + ''
  #       wrapProgram $out/bin/equibop \
  #         --prefix LD_LIBRARY_PATH : "${libPath}" \
  #         --set LIBVA_DRIVER_NAME "nvidia" \
  #         --set NVD_BACKEND "direct" \
  #         --add-flags "--enable-features=VaapiVideoEncoder,VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs,CanvasOopRasterization" \
  #         --add-flags "--disable-features=UseChromeOSDirectVideoDecoder" \
  #         --add-flags "--ozone-platform=wayland" \
  #         --add-flags "--disable-gpu-memory-buffer-video-frames"
  #     '';
  # });
in {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  options.custom = {
    programs.discord = {
      enable = lib.mkEnableOption "Discord via nixcord/equibop";
      plugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Nixcord plugins configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      #equibop.enable = true;
      #equibop.package = fixed-equibop;

      discord.enable = false;
      vesktop = {
        enable = true;
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
        plugins = cfg.plugins // {webRichPresence.enable = true;};
      };
    };

    custom.programs.niri.startupCommands = lib.mkIf config.custom.programs.niri.enable [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; vesktop --start-minimized > /dev/null 2>&1"''
    ];

    custom.programs.niri.windowRules = lib.mkIf config.custom.programs.niri.enable [
      ''        window-rule {
                  match app-id="vesktop" title="Discord Updater"
                  match app-id="vesktop" title="Checking for updates..."
                  open-floating true
                  open-maximized false
              }''
    ];
  };
}
