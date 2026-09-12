{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.services.beszel-agent;
in {
  options.custom.services.beszel-agent = {
    enable = lib.mkEnableOption "Beszel monitoring agent";

    key = lib.mkOption {
      type = lib.types.str;
      # Deployment-wide default: the public key of the beszel hub on windwaker.
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQAj+3OR1B8cBF0GrVs1jmTuy5snr6zoRaK67v+j42D";
      description = "Hub SSH public key for hub→agent SSH connections. Not secret.";
      example = "ssh-ed25519 AAAA...";
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a file containing the WebSocket registration token. Used for agent→hub connections via HUB_URL.";
      example = "/run/secrets/beszel-agent-token";
    };

    hubUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Hub URL for outgoing WebSocket connection. Leave empty when agent and hub are on the same host.";
      example = "http://10.0.10.16:8090";
    };

    extraFilesystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra block devices to track disk usage for (EXTRA_FILESYSTEMS).";
      example = ["sda" "sdb"];
    };

    gpuPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Packages added to the agent PATH for GPU monitoring (e.g. intel-gpu-tools, nvidia-smi).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the agent's SSH port (default 45876) on all interfaces. Only needed for hub-initiated (SSH) connections from an untrusted interface; agent-initiated HUB_URL connections and hubs reachable via a trusted interface (e.g. a Podman bridge) don't need this.";
    };

    capPerfmon = lib.mkEnableOption "Grant CAP_PERFMON to the agent service (required for intel_gpu_top)";

    gpuMonitoring = lib.mkEnableOption "GPU monitoring. Disables PrivateDevices so the agent can access /dev/dri and /dev/nvidia*.";

    intelGpuDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Intel GPU device path (INTEL_GPU_DEVICE). Set when intel_gpu_top can't auto-detect the GPU.";
      example = "drm:/dev/dri/card0";
    };
  };

  config = lib.mkIf cfg.enable {
    services.beszel.agent = {
      enable = true;
      inherit (cfg) openFirewall;
      extraPath = cfg.gpuPackages;
      environment =
        lib.optionalAttrs (cfg.key != "") {KEY = cfg.key;}
        // lib.optionalAttrs (cfg.tokenFile != null) {TOKEN_FILE = cfg.tokenFile;}
        // lib.optionalAttrs (cfg.intelGpuDevice != null) {INTEL_GPU_DEVICE = cfg.intelGpuDevice;}
        // lib.optionalAttrs (cfg.hubUrl != "") {HUB_URL = cfg.hubUrl;}
        // lib.optionalAttrs (cfg.extraFilesystems != []) {
          EXTRA_FILESYSTEMS = lib.concatStringsSep "," cfg.extraFilesystems;
        };
    };

    systemd.services.beszel-agent.serviceConfig = lib.mkMerge [
      (lib.mkIf cfg.capPerfmon {AmbientCapabilities = "CAP_PERFMON";})
      (lib.mkIf cfg.gpuMonitoring {
        PrivateDevices = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        ProtectKernelModules = lib.mkForce false;
        SystemCallFilter = lib.mkForce [];
      })
    ];
  };
}
