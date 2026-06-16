# Shared hardware profile: GPU shader-cache persistence, EasyEffects (with the
# mutable blue_yeti preset + micsave commit tool), OpenRGB, and optional
# liquidctl LCD. Parameterized by username for the per-user writable preset path.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.profiles.hardware;
  presetGitPath = "/persist/etc/nixos/modules/users/${cfg.username}/files/blue_yeti.json";
in {
  options.custom.profiles.hardware = {
    enable = lib.mkEnableOption "Hardware profile (EasyEffects, OpenRGB, shader cache)";
    username = lib.mkOption {
      type = lib.types.str;
      description = "Owning username; used to locate the per-user writable EasyEffects preset in the repo.";
    };
    liquidctl = lib.mkEnableOption "liquidctl LCD control (NZXT Kraken)";
    liquidctlLcdImage = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Image/GIF to display on the liquidctl LCD.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.persistence."/persist".directories = [
        ".cache/nvidia"
        ".cache/mesa_shader_cache"
        ".cache/radv_builtin_shaders"
      ];

      custom = {
        scripts.micsave = {
          enable = true;
          inherit presetGitPath;
        };

        programs = {
          easyeffects = {
            enable = true;
            preset = "blue_yeti";
            presetSource = presetGitPath;
          };
          openrgb.enable = true;
        };
      };
    }
    (lib.mkIf cfg.liquidctl {
      custom.programs.liquidctl = {
        enable = true;
        lcdImage = cfg.liquidctlLcdImage;
        brightness = 100;
        orientation = 270;
      };
    })
  ]);
}
