{ inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # System-level persistence only
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/NetworkManager"
      "/etc/NetworkManager/system-connections"
      "/system/sops/age"
    ];

    files = [
      "/etc/machine-id"
    ];
  };

  fileSystems."/home" = {
    device = "/persist/home";
    options = [ "bind" ];
    neededForBoot = true;
  };

  programs.fuse.userAllowOther = true;
}
