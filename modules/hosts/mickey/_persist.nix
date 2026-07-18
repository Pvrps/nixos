# Host-specific persistence on top of the shared base (modules/nixos/persist.nix).
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/systemd/coredump"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
      "/etc/rustdesk"
      "/root/.config/rustdesk"
      "/root/.local/share/rustdesk"
    ];

    files = [
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
          ".local/share/kwalletd"
          ".local/share/kactivitymanagerd"
          ".local/share/kscreen"
          ".local/share/activitywatch"
        ];
      };

      purps = {
        directories = [".ssh"];
        files = [".local/share/fish/fish_history"];
      };
    };
  };
}
