import ../_shared/disko-btrfs.nix {
  device = "/dev/nvme0n1";
  rootSize = "1.5T";
  # Disk-backed ephemeral / and /home (wiped by custom.impermanence.btrfsRollback).
  ephemeral = "btrfs";
}
