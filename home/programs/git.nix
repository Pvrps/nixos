{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "purps";
        email = "github@purps.ca";
      };
      core = {
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        autocrlf = true;
        sshCommand = "ssh";
      };
      init = {
        defaultBranch = "main";
      };
      commit = {
        gpgsign = false;
      };
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      fetch = {
        prune = true;
      };
      status = {
        showUntrackedFiles = "all";
      };
      http = {
        lowSpeedLimit = 1000;
        lowSpeedTime = 60;
        postBuffer = 524288000;
      };
      url = {
        "git@github.com:".insteadOf = [
          "gh:"
          "git://://github.com"
          "https://://github.com"
        ];
      };
      safe.directory = "/persist/etc/nixos";
    };
  };
}
