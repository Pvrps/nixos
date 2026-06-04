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

  fileSystems = {
    "/persist".neededForBoot = true;

    "/mnt/general" = {
      device = "/dev/disk/by-uuid/3b95b690-13a1-4052-bc81-ade5b51f2de1";
      fsType = "ext4";
      options = ["nofail" "x-systemd.device-timeout=10"];
    };

    "/mnt/media" = {
      device = "/dev/disk/by-uuid/c9af4659-a55a-4977-b83b-ae02bb4841c7";
      fsType = "ext4";
      options = ["nofail" "x-systemd.device-timeout=10"];
    };
  };
}
