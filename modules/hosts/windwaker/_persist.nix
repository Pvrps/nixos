# Host-specific persistence on top of the shared base (modules/nixos/persist.nix).
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/systemd/coredump"
      # Podman state and layer cache (grows over time; lives on sda btrfs)
      "/var/lib/containers"
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
}
