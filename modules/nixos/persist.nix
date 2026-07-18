# Impermanence base shared by all hosts: btrfs /persist with tmpfs /.
# Hosts add their own host-specific directories/files/users on top.
{inputs, ...}: {
  imports = [inputs.impermanence.nixosModules.impermanence];

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/tailscale"
    ];

    files = [
      "/etc/machine-id"
    ];
  };

  programs.fuse.userAllowOther = true;
}
