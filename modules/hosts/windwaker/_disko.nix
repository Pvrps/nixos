{lib, ...}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = ["-f"];
              subvolumes = {
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "/swap" = {
                  mountpoint = "/.swap";
                  swap.swapfile.size = "8G";
                };
              };
            };
          };
        };
      };
    };

    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = ["defaults" "size=2G" "mode=755"];
    };
  };

  # USB SSD partitions — existing data, not managed by disko
  # Podman depends on both — containers bind-mount from both partitions
  fileSystems = {
    "/persist".neededForBoot = true;

    "/mnt" = {
      device = "/dev/disk/by-uuid/3b95b690-13a1-4052-bc81-ade5b51f2de1";
      fsType = "ext4";
      options = ["nofail" "x-systemd.device-timeout=90" "x-systemd.automount"];
    };
  };
}
