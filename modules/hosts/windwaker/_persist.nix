{inputs, ...}: {
  imports = [inputs.impermanence.nixosModules.impermanence];

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      # Docker state and layer cache (grows over time; lives on sda btrfs)
      "/var/lib/docker"
      "/etc/docker"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users.purps = {
      directories = [
        ".ssh"
      ];
      files = [
        ".local/share/fish/fish_history"
      ];
    };
  };

  programs.fuse.userAllowOther = true;
}
