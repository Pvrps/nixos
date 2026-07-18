# Desktop workstation profile: the shared base for the gaming desktops
# (navi, ciela). Everything uses mkDefault so hosts can override per-line.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.profiles.workstation;
in {
  options.custom.profiles.workstation.enable =
    lib.mkEnableOption "desktop workstation profile (NVIDIA, gaming, low-latency audio, flatpak, bluetooth, RGB/fan control, beszel agent)";

  config = lib.mkIf cfg.enable {
    custom = {
      nvidia.enable = lib.mkDefault true;
      audio.lowLatency.enable = lib.mkDefault true;
      flatpak.enable = lib.mkDefault true;
      bluetooth.enable = lib.mkDefault true;
      hardwareControl.enable = lib.mkDefault true;

      gaming = {
        enable = lib.mkDefault true;
        steamRemotePlay.openFirewall = lib.mkDefault true;
        steamDedicatedServer.openFirewall = lib.mkDefault true;
      };

      services.beszel-agent = {
        enable = lib.mkDefault true;
        tokenFile = lib.mkDefault config.sops.secrets."beszel-agent-token".path;
        hubUrl = lib.mkDefault "http://windwaker:8090";
        gpuMonitoring = lib.mkDefault true;
      };
    };

    sops.secrets."beszel-agent-token" = {
      owner = "beszel-agent";
      group = "root";
      mode = "0600";
    };

    # Geist must be a system-level font so Flatpak exposes it via
    # /run/host/fonts; home-manager fonts live in the Nix store and aren't
    # reachable inside the sandbox.
    fonts.packages = [pkgs.geist-font];

    services = {
      upower.enable = true;
      gnome.gnome-keyring.enable = true;
    };

    environment.systemPackages = [pkgs.nix-your-shell];
  };
}
