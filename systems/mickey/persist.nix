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
          ".mozilla/firefox"
          ".local/share/kwalletd"
          ".local/share/kactivitymanagerd"
        ];
        files = [
          ".config/kdeglobals"
          ".config/kwalletrc"
          ".config/plasma-org.kde.plasma.desktop-appletsrc"
          ".config/plasmashellrc"
          ".config/kwinrc"
          ".config/kactivitymanagerdrc"
          ".config/kactivitymanagerd-pluginsrc"

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
