{config, ...}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./session.nix
    ./users.nix
  ];

  # roc-toolkit mic stream from ciela (Inori) — receiver ports for the RTP
  # source/repair/control endpoints, scoped to the tailscale interface only.
  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [10001 10002 10003];

  custom = {
    profiles.workstation.enable = true;
    desktop.portals.backend = "gnome";

    opentabletdriver.enable = true;
    bluetooth.guiTools = true;
    hardwareControl.liquidctl = true;

    #secureboot.enable = true;

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
