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
      default = "";
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
      example = [ "sda" "sdb" ];
    };

    gpuPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Packages added to the agent PATH for GPU monitoring (e.g. intel-gpu-tools, nvidia-smi).";
    };

    capPerfmon = lib.mkEnableOption "Grant CAP_PERFMON to the agent service (required for intel_gpu_top)";

    gpuMonitoring = lib.mkEnableOption "GPU monitoring. Disables PrivateDevices so the agent can access /dev/dri and /dev/nvidia*.";
  };

  config = lib.mkIf cfg.enable {
    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      extraPath = cfg.gpuPackages;
      environment =
        lib.optionalAttrs (cfg.key != "") { KEY = cfg.key; }
        // lib.optionalAttrs (cfg.tokenFile != null) { TOKEN_FILE = cfg.tokenFile; }
        // lib.optionalAttrs (cfg.hubUrl != "") { HUB_URL = cfg.hubUrl; }
        // lib.optionalAttrs (cfg.extraFilesystems != []) {
          EXTRA_FILESYSTEMS = lib.concatStringsSep "," cfg.extraFilesystems;
        };
    };

    systemd.services.beszel-agent.serviceConfig = lib.mkMerge [
      (lib.mkIf cfg.capPerfmon { AmbientCapabilities = "CAP_PERFMON"; })
      (lib.mkIf cfg.gpuMonitoring {
        PrivateDevices = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        ProtectKernelModules = lib.mkForce false;
      })
    ];
  };
}
