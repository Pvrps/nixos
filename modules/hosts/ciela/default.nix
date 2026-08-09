{config, ...}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./session.nix
    ./users.nix
  ];

  # amd-pstate-epp defaults to powersave; gamemoded is supposed to flip this
  # on demand but the Steam launch options aren't wired through gamemoderun,
  # so the 5900X sits at powersave even mid-match. Pin performance here until
  # gamemoded is actually invoked.
  powerManagement.cpuFreqGovernor = "performance";

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
