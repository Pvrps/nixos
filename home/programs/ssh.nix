{ ... }:
{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "/run/secrets/github-ssh-key";
      };
    };
  };
  services.ssh-agent.enable = true;
}
