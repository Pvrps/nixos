# Navi session: greetd/tuigreet + niri (tearing fork by default).
#
# mango is kept configured but disabled (custom.mango.enable below, plus
# custom.programs.mango.enable in users/purps/navi.nix): flip both back on to
# get the mango session in tuigreet's F3 list again.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.niri.tearingFork;
  mangoEnabled = config.custom.mango.enable;

  # urayde/niri, built against our nixpkgs through the fork's own overlay so
  # it uses the same toolchain/libraries as the rest of the system. Tests are
  # skipped: they only lengthen the (local, uncached) build.
  niriTearing = (inputs.niri-tearing.overlays.default pkgs pkgs).niri.overrideAttrs (_: {
    doCheck = false;
  });

  # See niri-wrapped.nix: silences the import-environment deprecation warning
  # printed on the TTY at login. Applies to both stock niri and the fork.
  niriPackage = pkgs.callPackage ./niri-wrapped.nix {
    niri =
      if cfg.enable
      then niriTearing
      else pkgs.niri;
  };

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
  options.custom = {
    niri.tearingFork.enable = lib.mkEnableOption ''
      the urayde/niri fork (screen tearing via the `allow-tearing` window rule,
      explicit sync) instead of nixpkgs' niri. Built locally (no binary cache)'';

    mango.enable = lib.mkEnableOption "the mango session (listed in tuigreet's session picker)";
  };

  config = lib.mkMerge [
    {
      custom.niri.tearingFork.enable = true;

      programs = {
        niri = {
          enable = true;
          package = niriPackage;
          useNautilus = false;
        };
        gpu-screen-recorder.enable = true;
      };

      security.pam.services.greetd.enableGnomeKeyring = true;

      services.greetd = {
        enable = true;
        # F3 in tuigreet lists every installed session.
        # --remember-session's choice lives in /var/cache/tuigreet, which is
        # wiped every boot (ephemeral /), so each boot starts on niri.
        settings.default_session = {
          command = lib.concatStringsSep " " [
            "${pkgs.tuigreet}/bin/tuigreet"
            "--time --remember --remember-session"
            "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
            "--cmd niri-session"
          ];
          user = "greeter";
        };
      };

      environment.systemPackages = [pkgs.seahorse];
    }

    (lib.mkIf mangoEnabled {
      programs.mango.enable = true;

      # nixpkgs' programs.mango module keys this as "ScreenShot", which
      # xdg-desktop-portal doesn't recognise (interface names are case-sensitive).
      xdg.portal.config.mango."org.freedesktop.impl.portal.Screenshot" = ["wlr"];

      services.udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="card[0-9]*", ATTRS{vendor}=="0x10de", SYMLINK+="dri/nvidia-card"
      '';

      environment.systemPackages = [mango-session];
    })
  ];
}
