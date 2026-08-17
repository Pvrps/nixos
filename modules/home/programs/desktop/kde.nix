# KDE Plasma desktop integration. Plasma runs on Wayland via SDDM, so this
# enables custom.system.wayland.enable (so Wayland-only scripts pass their
# assertions) and applies the session tweaks Plasma needs. Mirrors niri.nix so
# the two desktops are configured the same way.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.kde;
in {
  options.custom.programs.kde = {
    enable = lib.mkEnableOption "KDE Plasma desktop integration";
  };

  config = lib.mkIf cfg.enable {
    # niri and KDE both autostart a full session; running both gives two
    # competing desktops. KDE owns this check since it is the simpler module.
    assertions = [
      {
        assertion = !config.custom.programs.niri.enable;
        message = "custom.programs.kde and custom.programs.niri are mutually exclusive; enable only one desktop.";
      }
    ];

    custom.system.wayland.enable = true;

    # PowerDevil's ddcutil backend spins up a thread per monitor and can hang on
    # some displays; disable it (brightness via DBus still works).
    home.sessionVariables.POWERDEVIL_NO_DDCUTIL = "1";
  };
}
