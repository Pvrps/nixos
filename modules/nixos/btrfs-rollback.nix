# Disk-backed impermanence: wipe the btrfs `root` and `home` subvolumes on
# every boot, before they're mounted. Same clean slate as a tmpfs / and /home,
# but nothing lives in RAM (or gets pushed into swap under memory pressure).
#
# Pair with `ephemeral = "btrfs"` in the host's _disko.nix, which declares the
# subvolumes. The previous boot's subvolumes are deleted outright — nothing is
# kept, so anything not declared in environment/home persistence is gone.
{
  config,
  lib,
  utils,
  ...
}: let
  cfg = config.custom.impermanence.btrfsRollback;
  deviceUnit = "${utils.escapeSystemdPath cfg.device}.device";
in {
  options.custom.impermanence.btrfsRollback = {
    enable = lib.mkEnableOption "wiping the btrfs root/home subvolumes on every boot";

    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-partlabel/disk-main-root";
      description = "Block device holding the btrfs volume (disko's `disk-main-root` partition).";
    };

    subvolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["root" "home"];
      description = "Top-level subvolumes deleted and recreated empty on every boot.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "custom.impermanence.btrfsRollback requires boot.initrd.systemd.enable";
      }
    ];

    boot.initrd.systemd.services.btrfs-rollback = {
      description = "Delete and recreate ephemeral btrfs subvolumes";
      wantedBy = ["initrd.target"];
      requires = [deviceUnit];
      after = [deviceUnit];
      before = ["sysroot.mount"];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        set -u
        mnt=/btrfs_tmp
        mkdir -p "$mnt"
        mount -t btrfs -o subvolid=5 ${lib.escapeShellArg cfg.device} "$mnt"

        # Nested subvolumes (e.g. /var/lib/machines, container storage) must go
        # before their parent can be deleted.
        delete_subvolume_recursively() {
          local IFS=$'\n'
          for child in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "$mnt/$child"
          done
          btrfs subvolume delete "$1"
        }

        for sv in ${lib.escapeShellArgs cfg.subvolumes}; do
          if [ -e "$mnt/$sv" ]; then
            delete_subvolume_recursively "$mnt/$sv"
          fi
          btrfs subvolume create "$mnt/$sv"
        done

        umount "$mnt"
      '';
    };
  };
}
