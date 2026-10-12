# Standard single-disk impermanence layout shared by all hosts:
# GPT: 512M ESP + btrfs root (nix / persist / swap subvolumes) + ephemeral / and /home.
# Plain function (not a module) so each host's _disko.nix stays standalone —
# install.sh feeds those files directly to the disko CLI.
#
# `ephemeral` picks where the wiped-every-boot / and /home live:
#   "tmpfs" — RAM-backed. Simple, but every file written there costs RAM and
#             gets pushed into swap under memory pressure.
#   "btrfs" — disk-backed `root` and `home` subvolumes, recreated empty on
#             every boot by modules/nixos/btrfs-rollback.nix (the host must
#             also set custom.impermanence.btrfsRollback.enable).
{
  device,
  rootSize ? "100%",
  ephemeral ? "tmpfs",
}: let
  btrfsEphemeral = ephemeral == "btrfs";
  btrfsOpts = ["compress=zstd" "noatime"];
in
  assert builtins.elem ephemeral ["tmpfs" "btrfs"]; {
    disko.devices =
      {
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
                  subvolumes =
                    {
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = btrfsOpts;
                      };
                      "/persist" = {
                        mountpoint = "/persist";
                        mountOptions = btrfsOpts;
                      };
                      "/swap" = {
                        mountpoint = "/.swap";
                        swap.swapfile.size = "8G";
                      };
                    }
                    // (
                      if btrfsEphemeral
                      then {
                        "/root" = {
                          mountpoint = "/";
                          mountOptions = btrfsOpts;
                        };
                        "/home" = {
                          mountpoint = "/home";
                          mountOptions = btrfsOpts;
                        };
                      }
                      else {}
                    );
                };
              };
            };
          };
        };
      }
      // (
        if btrfsEphemeral
        then {}
        else {
          nodev."/" = {
            fsType = "tmpfs";
            mountOptions = ["defaults" "size=2G" "mode=755"];
          };
        }
      );

    fileSystems =
      {
        "/persist".neededForBoot = true;
      }
      // (
        if btrfsEphemeral
        then {"/home".neededForBoot = true;}
        else {}
      );
  }
