# Host-specific persistence on top of the shared base (modules/nixos/persist.nix).
# User-level persistence for purps lives in home-manager (modules/users/purps/navi.nix).
{
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/systemd/coredump"
      "/var/lib/NetworkManager"
      "/var/lib/greetd"
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
    ];
  };

  fileSystems."/home" = {
    device = "none";
    fsType = "tmpfs";
    options = ["defaults" "mode=755"];
    neededForBoot = true;
  };
}
