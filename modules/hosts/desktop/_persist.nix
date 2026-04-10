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
      "/var/lib/greetd"
      "/var/lib/tailscale"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
    ];
  };

  fileSystems."/home" = {
    device = "/persist/home";
    fsType = "none";
    options = ["bind"];
    neededForBoot = true;
  };

  programs.fuse.userAllowOther = true;
}
