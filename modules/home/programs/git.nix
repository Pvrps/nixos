{
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.git;
in {
  options.custom.programs.git = {
    enable = lib.mkEnableOption "Git version control";
    userName = lib.mkOption {
      type = lib.types.str;
      default = "Anonymous";
      description = "Git user name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "anonymous@localhost";
      description = "Git user email";
    };
    safeDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["/persist/etc/nixos"];
      description = "Directories to mark as safe (git safe.directory), e.g. root-owned repos.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      attributes = [
        "* text=auto eol=lf"
      ];
      settings = {
        user = {
          name = cfg.userName;
          email = cfg.userEmail;
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
          ];
        };
        credential."https://github.com".helper = "!f() { test \"$1\" = get && test -f /run/secrets/github-token && echo \"username=x-access-token\" && echo \"password=$(cat /run/secrets/github-token)\"; }; f";
        safe.directory = cfg.safeDirectories;
      };
    };
  };
}
