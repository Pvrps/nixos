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
  # /dev/sdb1 = 250G /mnt/general (docker volumes, compose files, .env files)
  # /dev/sdb2 = 681G /mnt/media    (media library)
  fileSystems = {
    "/persist".neededForBoot = true;

    "/mnt/general" = {
      device = "/dev/sdb1";
      fsType = "ext4";
      options = ["nofail" "x-systemd.device-timeout=10"];
    };

    "/mnt/media" = {
      device = "/dev/sdb2";
      fsType = "ext4";
      options = ["nofail" "x-systemd.device-timeout=10"];
    };
  };
}
