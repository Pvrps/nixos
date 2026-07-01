{
  pkgs,
  config,
  inputs,
  lib,
  osConfig,
  ...
}: let
  cfg = config.custom.programs.discord;
  # pnpm_10_29_2 is marked insecure in nixpkgs but is needed by vesktop's lockfile
  safe-pnpm = pkgs.pnpm_10_29_2.overrideAttrs (old: {
    meta = (old.meta or {}) // { knownVulnerabilities = []; };
  });
  safe-vesktop = pkgs.vesktop.override {
    pnpm_10_29_2 = safe-pnpm;
  };
  fixed-vesktop = safe-vesktop.overrideAttrs (old: {
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
