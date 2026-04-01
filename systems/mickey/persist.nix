{inputs, ...}: {
  imports = [inputs.impermanence.nixosModules.impermanence];

  # System-level persistence only
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/etc/ssh"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"
      "/var/lib/tailscale"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
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
