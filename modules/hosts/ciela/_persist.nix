# Host-specific persistence on top of the shared base (modules/nixos/persist.nix).
{
  environment.persistence."/persist" = {
    directories = [
      # Intentionally NOT persisting /var/lib/systemd/coredump: stale dumps
      # accumulate and DrKonqi replays them as crash popups on every login.
      "/var/lib/NetworkManager"
      "/var/lib/sddm"
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users.purps = {
      directories = [".ssh"];
      files = [".local/share/fish/fish_history"];
    };
  };

  fileSystems."/home" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "mode=755"];
    neededForBoot = true;
  };
}
