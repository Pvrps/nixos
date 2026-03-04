{
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.git;
in {
  options.custom.programs.git.enable = lib.mkEnableOption "Git version control";

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      attributes = [
        "* text=auto eol=lf"
      ];
      settings = {
        user = {
          name = config.custom.git.userName;
          email = config.custom.git.userEmail;
        };
        core = {
          whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
          autocrlf = false;
          sshCommand = "ssh";
        };
        init = {
          defaultBranch = "main";
        };
        commit = {
          gpgsign = false; # TODO: configure GPG signing
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
            "git://github.com/"
            "https://github.com/"
          ];
        };
        safe.directory = "/persist/etc/nixos";
      };
    };
  };
}
