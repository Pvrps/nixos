{config, ...}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./session.nix
    ./users.nix
  ];

  # amd-pstate-epp defaults to powersave. gamemoded flips it on demand, but only
  # for processes launched through gamemoderun -- anything started outside that
  # path (and Steam's own shader compilation) stays on the low-power EPP hint.
  # Pin performance instead; C-states still idle the cores on a desktop part.
  powerManagement.cpuFreqGovernor = "performance";

  # roc-toolkit mic stream from ciela (Inori) — receiver ports for the RTP
  # source/repair/control endpoints, scoped to the tailscale interface only.
  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [10001 10002 10003];

  custom = {
    profiles.workstation.enable = true;
    desktop.portals.backend = "gnome";

    opentabletdriver.enable = true;
    bluetooth.guiTools = true;
    hardwareControl.liquidctl = true;

    # / and /home are btrfs subvolumes recreated on every boot (see _disko.nix),
    # instead of RAM-backed tmpfs.
    impermanence.btrfsRollback.enable = true;

    #secureboot.enable = true;

    # Reverse-engineering microVM + `rea` launcher (modules/users/purps/REA.md)
    reaVm = {
      enable = true;
      externalInterface = "eno1";
      # VLANs the VM may reach (behind OpenSnitch prompts). Their routers
      # (.1) are blocked automatically; every other VLAN (Default, Server,
      # DMZ, Work, Hotspot) and private range stays blocked.
      lanAllowed = [
        "10.0.20.0/24" # WiFi, VLAN 20 (TCL TV)
        "10.10.30.0/24" # IoT, VLAN 130 (Blink sync module)
      ];
    };

    services.sshfs = {
      enable = true;
      mounts = {
        windwaker = {
          host = "10.0.10.16";
          user = "purps";
          remotePath = "/mnt/";
          identityFile = config.sops.secrets."windwaker-purps-key".path;
          mountPoint = "/mnt/windwaker";
          allowOther = true;
          knownHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzhmSCILV7cN4qukQz50I2YpEsPiT6DfsJiPdLf9pUr";
        };
      };
    };
  };
}
