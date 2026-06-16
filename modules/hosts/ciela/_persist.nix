{inputs, ...}: {
  imports = [inputs.impermanence.nixosModules.impermanence];

  # System-level persistence only
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/NetworkManager"
      "/var/lib/sddm"
      "/var/lib/tailscale"
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };

  fileSystems."/home" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "mode=755"];
    neededForBoot = true;
  };

  programs.fuse.userAllowOther = true;
}
