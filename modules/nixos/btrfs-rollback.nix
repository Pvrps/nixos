# Disk-backed impermanence: wipe the btrfs `root` and `home` subvolumes on
# every boot, before they're mounted. Same clean slate as a tmpfs / and /home,
# but nothing lives in RAM (or gets pushed into swap under memory pressure).
#
# Pair with `ephemeral = "btrfs"` in the host's _disko.nix, which declares the
# subvolumes. Previous roots are moved to `old_roots/<name>-<timestamp>` on the
# top-level btrfs volume and deleted after `keepDays`, so a file you forgot to
# persist can still be recovered:
#   sudo mount -o subvolid=5 /dev/disk/by-partlabel/disk-main-root /mnt
#   ls /mnt/old_roots
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
      description = "Top-level subvolumes recreated empty on every boot.";
    };

    keepDays = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 7;
      description = "Delete archived roots in old_roots/ older than this many days.";
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
      description = "Archive and recreate ephemeral btrfs subvolumes";
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
        mkdir -p "$mnt/old_roots"

        delete_subvolume_recursively() {
          local IFS=$'\n'
          for child in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "$mnt/$child"
          done
          btrfs subvolume delete "$1"
        }

        # Archive the previous boot's subvolumes.
        for sv in ${lib.escapeShellArgs cfg.subvolumes}; do
          if [ -e "$mnt/$sv" ]; then
            ts=$(date --date="@$(stat -c %Y "$mnt/$sv")" "+%Y-%m-%d_%H-%M-%S")
            dest="$mnt/old_roots/$sv-$ts"
            n=0
            while [ -e "$dest" ]; do n=$((n + 1)); dest="$mnt/old_roots/$sv-$ts.$n"; done
            mv "$mnt/$sv" "$dest"
          fi
        done

        # Prune old archives. Failures here must not block boot.
        for old in $(find "$mnt/old_roots" -mindepth 1 -maxdepth 1 -mtime +${toString cfg.keepDays}); do
          delete_subvolume_recursively "$old" || echo "btrfs-rollback: failed to delete $old" >&2
        done

        # Fresh, empty subvolumes for this boot.
        for sv in ${lib.escapeShellArgs cfg.subvolumes}; do
          btrfs subvolume create "$mnt/$sv"
        done

        umount "$mnt"
      '';
    };
  };
}
