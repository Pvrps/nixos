import ../_shared/disko-btrfs.nix {
  device = "/dev/nvme0n1";
  rootSize = "1.5T";
}
