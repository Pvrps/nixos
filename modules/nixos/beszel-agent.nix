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
      description = "Hub SSH public key (shown in the Add System dialog). Not secret.";
      example = "ssh-ed25519 AAAA...";
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

    tokenFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to a file containing TOKEN=<token>. Use a sops-managed secret.";
      example = "/run/secrets/beszel-agent-token";
    };

    capPerfmon = lib.mkEnableOption "Grant CAP_PERFMON to the agent service (required for intel_gpu_top)";
  };

  config = lib.mkIf cfg.enable {
    services.beszel.agent = {
      enable = true;
      openFirewall = true;
      environmentFile = cfg.tokenFile;
      extraPath = cfg.gpuPackages;
      environment =
        lib.optionalAttrs (cfg.key != "") { KEY = cfg.key; }
        // lib.optionalAttrs (cfg.hubUrl != "") { HUB_URL = cfg.hubUrl; }
        // lib.optionalAttrs (cfg.extraFilesystems != []) {
          EXTRA_FILESYSTEMS = lib.concatStringsSep " " cfg.extraFilesystems;
        };
    };

    systemd.services.beszel-agent.serviceConfig.AmbientCapabilities =
      lib.mkIf cfg.capPerfmon "CAP_PERFMON";
  };
}
