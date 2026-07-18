# Standard single-disk impermanence layout shared by all hosts:
# GPT: 512M ESP + btrfs root (nix / persist / swap subvolumes), tmpfs /.
# Plain function (not a module) so each host's _disko.nix stays standalone —
# install.sh feeds those files directly to the disko CLI.
{
  device,
  rootSize ? "100%",
}: {
  disko.devices = {
    disk.main = {
      type = "disk";
      inherit device;
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
            size = rootSize;
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

  fileSystems."/persist".neededForBoot = true;
}
