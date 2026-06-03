{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.yazi;

  # The Sixel encoder in yazi composites RGBA images onto black before
  # palette-quantising them, making dark content on transparent backgrounds
  # invisible (black-on-black).  This is specific to the Sixel protocol used
  # by foot; KGP terminals like Ghostty carry RGBA natively so they are
  # unaffected.  The patch replaces the `to_rgb8()` call with a proper
  # alpha-composite onto a neutral grey checkerboard — the conventional way to
  # display transparency when the background colour is unknown.
  patched-yazi = pkgs.yazi.override {
    yazi-unwrapped = pkgs.yazi-unwrapped.overrideAttrs (old: {
      patches = (old.patches or []) ++ [../patches/yazi-sixel-alpha.patch];
    });
  };
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
      package = patched-yazi;
    };
  };
}
