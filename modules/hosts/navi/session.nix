# Navi session: greetd/tuigreet + mango (default) or niri (pick with F3).
{
  config,
  lib,
  pkgs,
  ...
}: let
  mango = config.programs.mango.package;

  # Launch mango as a login session. niri gets this from niri-session; mango
  # has no wrapper of its own, so:
  #   - source home-manager's session variables (NIXOS_OZONE_WL, ...), which
  #     /etc/profile does not, and set the XDG session identity;
  #   - pin wlroots to the NVIDIA card only: both monitors hang off it, and
  #     wlroots' multi-GPU path (the Raphael iGPU is also a DRM device) costs
  #     an extra copy per frame for no gain. /dev/dri/nvidia-card is a stable
  #     udev symlink below (cardN numbering isn't stable across boots, and
  #     by-path names contain ':' which WLR_DRM_DEVICES uses as separator);
  #   - send mango's log to the journal (`journalctl --user -t mango`).
  mango-session = pkgs.writeShellScriptBin "mango-session" ''
    hm_vars="/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
    # shellcheck disable=SC1090
    [ -r "$hm_vars" ] && . "$hm_vars"

    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=mango
    export XDG_CURRENT_DESKTOP=mango
    if [ -e /dev/dri/nvidia-card ]; then
      export WLR_DRM_DEVICES=/dev/dri/nvidia-card
    fi

    exec ${pkgs.systemd}/bin/systemd-cat --identifier=mango ${lib.getExe mango}
  '';
in {
  programs = {
    mango.enable = true;
    niri = {
      enable = true;
      # See niri-wrapped.nix: silences the import-environment deprecation
      # warning printed on the TTY at login.
      package = pkgs.callPackage ./niri-wrapped.nix {};
      useNautilus = false;
    };
    gpu-screen-recorder.enable = true;
  };

  # nixpkgs' programs.mango module keys this as "ScreenShot", which
  # xdg-desktop-portal doesn't recognise (interface names are case-sensitive).
  xdg.portal.config.mango."org.freedesktop.impl.portal.Screenshot" = ["wlr"];

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ATTRS{vendor}=="0x10de", SYMLINK+="dri/nvidia-card"
  '';

  security.pam.services.greetd.enableGnomeKeyring = true;

  services.greetd = {
    enable = true;
    # Default to mango; F3 in tuigreet lists every installed session (niri
    # included). --remember-session's choice lives in /var/cache/tuigreet,
    # which is wiped every boot (ephemeral /), so each boot starts on mango.
    settings.default_session = {
      command = lib.concatStringsSep " " [
        "${pkgs.tuigreet}/bin/tuigreet"
        "--time --remember --remember-session"
        "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
        "--cmd ${lib.getExe mango-session}"
      ];
      user = "greeter";
    };
  };

  environment.systemPackages = [pkgs.seahorse mango-session];
}
