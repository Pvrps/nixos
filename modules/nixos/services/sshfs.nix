{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.services.sshfs;
in {
  options.custom.services.sshfs = {
    enable = lib.mkEnableOption "SSHFS automounting services";

    mounts = lib.mkOption {
      description = "List of SSHFS mounts to manage.";
      default = {};
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "SSH Host to connect to.";
          };
          user = lib.mkOption {
            type = lib.types.str;
            description = "SSH User to connect as.";
          };
          port = lib.mkOption {
            type = lib.types.int;
            default = 22;
            description = "SSH Port to connect to.";
          };
          passwordSecret = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Absolute path to the secret file containing the password.";
          };
          mountPoint = lib.mkOption {
            type = lib.types.str;
            description = "Absolute path where the remote filesystem should be mounted.";
          };
          extraOptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "StrictHostKeyChecking=accept-new"
              "reconnect"
              "ServerAliveInterval=15"
              "ServerAliveCountMax=3"
              "allow_other"
            ];
            description = "Extra options to pass to sshfs (-o).";
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.sshfs];

    programs.fuse.userAllowOther = true;

    systemd.services = lib.mapAttrs' (name: mountCfg: let
      hasPassword = mountCfg.passwordSecret != null;
      options = lib.concatStringsSep "," (mountCfg.extraOptions ++ lib.optional hasPassword "password_stdin");

      sshfsCmd = "${pkgs.sshfs}/bin/sshfs ${mountCfg.user}@${mountCfg.host}:/ ${mountCfg.mountPoint} -p ${toString mountCfg.port} -f -o ${options}";

      execStartCmd =
        if hasPassword
        then "${pkgs.bash}/bin/bash -c \"cat ${mountCfg.passwordSecret} | ${sshfsCmd}\""
        else sshfsCmd;
    in
      lib.nameValuePair "sshfs-${name}" {
        description = "Mount ${name} via SSHFS";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Type = "simple";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountCfg.mountPoint}";
          ExecStart = execStartCmd;
          ExecStop = "/run/wrappers/bin/fusermount3 -u ${mountCfg.mountPoint}";
          Restart = "always";
          RestartSec = "10";
        };
      })
    cfg.mounts;
  };
}
