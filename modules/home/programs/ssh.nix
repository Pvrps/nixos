{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.ssh;
in {
  options.custom = {
    programs.ssh = {
      enable = lib.mkEnableOption "SSH client configuration";
      githubKeyPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the SSH key for github.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;

      settings = lib.mkMerge [
        {
          "*" = {
            AddKeysToAgent = "yes";
            ForwardAgent = false;
            Compression = false;
            ServerAliveInterval = 60;
            ServerAliveCountMax = 3;
            HashKnownHosts = false;
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
          };
        }
        (lib.mkIf (cfg.githubKeyPath != null) {
          "github.com" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = cfg.githubKeyPath;
          };
        })
      ];
    };
    services.ssh-agent.enable = true;
  };
}
