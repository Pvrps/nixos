{lib, config, ...}: let
  cfg = config.custom.programs.foot;
in {
  options.custom.programs.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "foot module requires a Wayland compositor to be enabled (e.g. custom.programs.niri.enable = true).";
      }
    ];

    programs.foot = {
      enable = true;
      settings = {
      };
    };

    custom.niri.keybinds = [
      ''Mod+Return { spawn "foot"; }''
    ];
  };
}
