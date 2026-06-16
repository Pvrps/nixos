# Flatpak with a first-boot network-ordering fix. Shared by desktop hosts.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.flatpak;
in {
  options.custom.flatpak.enable = lib.mkEnableOption "Flatpak support";

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    # nix-flatpak's generated service only has After=multi-user.target and fails
    # on first boot attempt because DNS isn't available yet. Override to wait for
    # network-online.target so the flathub remote lookup succeeds on first try.
    systemd.services.flatpak-managed-install = {
      wants = ["network-online.target"];
      after = ["network-online.target"];
    };
  };
}
