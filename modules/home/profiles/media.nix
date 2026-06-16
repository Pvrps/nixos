# Shared media profile: OBS, Spotify, Stremio, Clapper, Okular, Pinta, Flatseal,
# and RustDesk. purps-only extras (chatterino, imv, audiobook scripts) gated by
# the `extras` option.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.profiles.media;
in {
  options.custom.profiles.media = {
    enable = lib.mkEnableOption "Media/streaming profile (OBS, Spotify, Stremio, RustDesk, ...)";
    extras = lib.mkEnableOption "Extra media tools: chatterino, imv, 2m4b, abd audiobook scripts";
    rustdeskServerFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the RustDesk server-address file (e.g. a sops secret path).";
    };
    rustdeskKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the RustDesk server public-key file (e.g. a sops secret path).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      custom.programs = {
        stremio.enable = true;
        clapper.enable = true;
        spotify.enable = true;
        okular.enable = true;
        pinta.enable = true;

        rustdesk = {
          enable = true;
          serverFile = cfg.rustdeskServerFile;
          keyFile = cfg.rustdeskKeyFile;
        };

        flatpak = {
          enable = true;
          packages = [
            "com.github.tchx84.Flatseal"
          ];
        };

        obs = {
          enable = true;
          plugins = {
            aitumStreamSuite = {
              enable = true;
              version = "1.1.2";
              hash = "sha256:46137e8ec8b92704879c58ed486bede468102935e53d25f3f1a36a5e07c71bca";
            };
            pipewireAudioCapture = {
              enable = true;
              version = "1.2.1";
              hash = "sha256:e3bfa510bf3cfccdba092ee726e7e0d3cbe433dd49d4101f6a3e2b7fa68eae84";
            };
          };
        };
      };
    }
    (lib.mkIf cfg.extras {
      custom.scripts."2m4b".enable = true;
      custom.scripts.abd.enable = true;
      custom.programs.chatterino.enable = true;
      custom.programs.imv.enable = true;
    })
  ]);
}
