{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.yazi;

  # WORKAROUND: yazi Sixel alpha compositing (foot), see WORKAROUNDS.md
  patched-yazi = pkgs.yazi.override {
    yazi-unwrapped = pkgs.yazi-unwrapped.overrideAttrs (old: {
      patches = (old.patches or []) ++ [../../patches/yazi-sixel-alpha.patch];
    });
  };
in {
  options.custom.programs.yazi = {
    enable = lib.mkEnableOption "Yazi terminal file manager";
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      # Patch only with foot; other hosts keep the cached pkgs.yazi.
      package =
        if config.custom.programs.foot.enable
        then patched-yazi
        else pkgs.yazi;
    };
  };
}
