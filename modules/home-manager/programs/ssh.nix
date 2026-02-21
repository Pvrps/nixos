{
  lib,
  config,
  ...
}: {
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    matchBlocks = lib.mkMerge [
      {
        "*" = {
          addKeysToAgent = "yes";

          # Defaults
          forwardAgent = false;
          compression = false;
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
      }
      (lib.mkIf (config.custom.ssh.githubKeyPath != null) {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = config.custom.ssh.githubKeyPath;
        };
      })
    ];
  };
  services.ssh-agent.enable = true;
}
