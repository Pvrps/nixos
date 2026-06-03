{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.yazi;
  # Use the terminal background colour (stylix base00) so that transparent
  # areas in PNG/WebP files are composited onto the theme background rather
  # than ImageMagick's default black.  The magick preset previewer gained
  # --bg support in yazi ≥ 25.9 (PR #3189).
  bg = "#${config.lib.stylix.colors.base00}";
in {
  options.custom = {
    programs.yazi = {
      enable = lib.mkEnableOption "Yazi terminal file manager";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      settings.plugin = {
        # Override the magick preloader/previewer for PNG and WebP so that
        # transparent pixels are composited onto the theme background colour
        # instead of black (ImageMagick's default when alpha is removed).
        prepend_preloaders = [
          {
            mime = "image/png";
            run = "magick --bg=${bg}";
          }
          {
            mime = "image/webp";
            run = "magick --bg=${bg}";
          }
        ];
        prepend_previewers = [
          {
            mime = "image/png";
            run = "magick --bg=${bg}";
          }
          {
            mime = "image/webp";
            run = "magick --bg=${bg}";
          }
        ];
      };
    };
  };
}
