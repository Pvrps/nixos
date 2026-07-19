{config, ...}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./session.nix
    ./users.nix
  ];

  custom = {
    profiles.workstation.enable = true;
    desktop.portals.backend = "kde";
    remoteAdmin.enable = true;

    # Root daemon so purps can *control* (not just view) inori's Wayland
    # session; it provides the privileged uinput input-injection services
    # and spawns the session server as her user for portal screen capture.
    services.rustdesk = {
      enable = true;
      serverFile = config.sops.secrets."rustdesk-server".path;
      keyFile = config.sops.secrets."rustdesk-key".path;
      passwordFile = config.sops.secrets."rustdesk-password".path;
    };
  };
}
