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
      "/var/lib/bluetooth"
      "/var/lib/tailscale"
      "/etc/NetworkManager/system-connections"
      "/etc/rustdesk"
      "/root/.config/rustdesk"
      "/root/.local/share/rustdesk"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users = {
      mike = {
        directories = [
          "Downloads"
          "Documents"
          "Desktop"
          ".config"
          ".mozilla/firefox"
          ".local/share/kwalletd"
          ".local/share/kactivitymanagerd"
          ".local/share/kscreen"
        ];
      };

      purps = {
        directories = [
          ".ssh"
        ];
        files = [
          ".local/share/fish/fish_history"
        ];
      };
    };
  };

  programs.fuse.userAllowOther = true;
}
