{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.gaming;
in {
  options.custom.gaming = {
    enable = lib.mkEnableOption "gaming support";
    steamRemotePlay.openFirewall = lib.mkEnableOption "Steam Remote Play firewall ports";
    steamDedicatedServer.openFirewall = lib.mkEnableOption "Steam dedicated server firewall ports";

    scx = {
      enable = lib.mkEnableOption "sched_ext userspace scheduler (scx)";
      scheduler = lib.mkOption {
        type = lib.types.str;
        default = "scx_lavd";
        description = ''
          sched_ext scheduler to run. `scx_lavd` (Latency-criticality Aware
          Virtual Deadline) is upstream's gaming-oriented scheduler and targets
          single-CCX desktops. Swap to `scx_bpfland` if lavd misbehaves.
        '';
      };
    };

    # CachyOS builds its kernels with PREEMPT full rather than the PREEMPT_LAZY
    # default that nixpkgs ships, on the grounds that lazy preemption hurts both
    # throughput and latency. Our kernel is PREEMPT_DYNAMIC, so this is a boot
    # parameter rather than a rebuild -- left off until A/B tested.
    preemptFull = lib.mkEnableOption "boot with preempt=full instead of the kernel's lazy default";
  };

  config = lib.mkIf cfg.enable {
    # uinput is required for Steam Input to create virtual controller devices.
    # The input group is powerful; keep this only for trusted local users.
    boot.kernelModules = ["uinput"];

    boot.kernelParams = lib.mkIf cfg.preemptFull ["preempt=full"];

    # Split-lock mitigation stalls every core for the duration of a misaligned
    # atomic. Plenty of Windows games trip it under Proton and the resulting
    # system-wide hitching is the single biggest thing gamemode turns off
    # per-title; doing it globally means it applies regardless of how a game was
    # launched. Trade-off: a buggy or hostile process can now degrade the whole
    # machine with split locks, which is acceptable on a single-user desktop.
    boot.kernel.sysctl."kernel.split_lock_mitigate" = 0;

    # uinput must be writable by the input group for Steam Input to create virtual devices.
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660"
    '';

    # xpadneo: advanced Xbox/8BitDo BT driver, fixes GET_REPORT timeouts and ERTM issues.
    hardware.xpadneo.enable = true;

    # Userspace sched_ext scheduler. Requires CONFIG_SCHED_CLASS_EXT, which the
    # nixpkgs kernel has enabled since 6.12; the unit additionally guards on
    # /sys/kernel/sched_ext existing. Unloading (`systemctl stop scx`) hands
    # scheduling straight back to EEVDF with no reboot.
    services.scx = lib.mkIf cfg.scx.enable {
      enable = true;
      inherit (cfg.scx) scheduler;
    };

    programs = {
      steam = {
        enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = cfg.steamRemotePlay.openFirewall;
        dedicatedServer.openFirewall = cfg.steamDedicatedServer.openFirewall;

        # MANGOHUD=1 only inside Steam's FHS env, so the overlay shows up on
        # games without leaking onto every other Vulkan/GL app on the system
        # (browsers, OBS, video players). Proton inherits it: pressure-vessel
        # passes the environment into the container and imports host Vulkan
        # layers by default. MangoHud's built-in blacklist already skips the
        # Steam client, steamwebhelper, gamescope and the usual launchers.
        # Native OpenGL titles still need the `mangohud` wrapper.
        package = pkgs.steam.override {
          extraEnv.MANGOHUD = true;
        };
      };

      # Opt-in per title via `gamemoderun %command%` in Steam launch options.
      # Do NOT wrap the Steam client itself in gamemoderun to get this for free:
      # LD_PRELOAD propagates to every process Steam spawns, and
      # libgamemodeauto inside steamwebhelper breaks the CEF transport
      # (Steam error 0x3009). The two effects worth having globally are applied
      # unconditionally instead -- see the performance governor on navi and
      # kernel.split_lock_mitigate in core.nix.
      gamemode = {
        enable = true;
        settings.general = {
          # Renicing a game above the compositor can starve niri and make frame
          # pacing worse on Wayland; leave at the upstream default and treat it
          # as an A/B knob rather than a default.
          renice = 0;
        };
      };

      gamescope.enable = true;
    };
  };
}
