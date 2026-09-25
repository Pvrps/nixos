# scrcpy — mirror and control an Android device (phone, tablet, Android TV)
# over USB or TCP/IP.
#
# Two things here are not obvious:
#
#   1. `android-tools` is listed explicitly even though pkgs.scrcpy already
#      wrapProgram's adb onto its own PATH. That wrapper is private to the
#      scrcpy binary, so without this there is no `adb` in the shell for the
#      connect / devices / disconnect cycle that wireless use inevitably needs.
#
#   2. `.android` must be persisted. It holds adbkey/adbkey.pub, the keypair the
#      device authorises once via its on-screen "Allow debugging?" prompt. It
#      lives outside the persisted .config/.local, so on a tmpfs home it is lost
#      every reboot and the device re-prompts — and for a TV that means walking
#      to it with a remote each time.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.scrcpy;

  # Wireless helper: adb reaches network devices only after an explicit
  # `adb connect`, and a device that dropped the connection lingers as
  # "offline" instead of reconnecting. Both are papered over here so the common
  # case is one command.
  scrcpy-wireless = pkgs.writeShellApplication {
    name = "scrcpy-wireless";
    runtimeInputs = [pkgs.android-tools pkgs.scrcpy pkgs.coreutils pkgs.gnugrep];
    text = ''
      addr=${lib.escapeShellArg (lib.optionalString (cfg.address != null) cfg.address)}

      # A leading '-' means it is a scrcpy flag, not an address, so the default
      # still applies: `scrcpy-wireless --fullscreen` must keep working.
      if [ $# -gt 0 ]; then
        case "$1" in
          -*) ;;
          *)
            addr="$1"
            shift
            ;;
        esac
      fi

      if [ -z "$addr" ]; then
        echo "usage: scrcpy-wireless [host[:port]] [scrcpy args...]" >&2
        echo "no address given and custom.programs.scrcpy.address is unset" >&2
        exit 1
      fi

      # Bare host: adb needs an explicit port, it does not assume 5555.
      case "$addr" in
        *:*) ;;
        *) addr="$addr:5555" ;;
      esac

      # Clear a stale "offline" entry first, otherwise connect is a no-op and
      # scrcpy then fails against a dead socket.
      # Braces are required: shellcheck reads a bare $addr[ as an array index.
      if adb devices | grep -q "^''${addr}[[:space:]]*offline"; then
        adb disconnect "$addr" >/dev/null 2>&1 || true
      fi

      # adb connect exits 0 even when it failed, so match on the message.
      out=$(adb connect "$addr" 2>&1) || true
      printf '%s\n' "$out"
      case "$out" in
        *"connected to"*) ;;
        *)
          echo "scrcpy-wireless: could not reach $addr" >&2
          echo "check the device is powered on and has wireless/network debugging enabled" >&2
          exit 1
          ;;
      esac

      # A new key must be accepted on the device before the state leaves
      # "unauthorized"; say so rather than letting scrcpy fail opaquely.
      state=""
      warned=0
      for _ in $(seq 1 ${toString cfg.connectTimeout}); do
        state=$(adb -s "$addr" get-state 2>/dev/null || true)
        [ "$state" = "device" ] && break
        if [ "$state" = "unauthorized" ] && [ "$warned" -eq 0 ]; then
          warned=1
          echo "scrcpy-wireless: accept the debugging prompt on the device to continue..." >&2
        fi
        sleep 1
      done

      if [ "$state" != "device" ]; then
        echo "scrcpy-wireless: $addr never became ready (state: ''${state:-unknown})" >&2
        exit 1
      fi

      exec scrcpy -s "$addr" ${lib.escapeShellArgs cfg.extraArgs} "$@"
    '';
  };
in {
  options.custom.programs.scrcpy = {
    enable = lib.mkEnableOption "scrcpy Android device mirroring and control";

    address = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.0.20.155:5555";
      description = ''
        Default device address for the scrcpy-wireless helper, as host or
        host:port (port defaults to 5555). Prefer an IP or a name resolvable
        from this host: adb's mDNS discovery relies on multicast and so does not
        cross subnets. Null installs scrcpy without the helper.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--max-size=1280" "--video-bit-rate=8M"];
      description = "Arguments the scrcpy-wireless helper always passes to scrcpy. Command-line arguments are appended after these, so they win.";
    };

    connectTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Seconds the scrcpy-wireless helper waits for the device to reach the `device` state, which includes time to accept an on-screen debugging prompt.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [
        pkgs.scrcpy
        pkgs.android-tools
      ]
      ++ lib.optional (cfg.address != null) scrcpy-wireless;

    # adbkey/adbkey.pub — see the header note.
    home.persistence."/persist".directories = [".android"];
  };
}
