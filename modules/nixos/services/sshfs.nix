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
          remotePath = lib.mkOption {
            type = lib.types.str;
            default = "/";
            description = "Remote path to mount.";
          };
          identityFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to SSH private key file";
          };
          knownHostKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "ssh-ed25519 AAAAC3Nz...";
            description = ''
              Pinned SSH host public key for the remote. When set, host identity
              is verified against this key (StrictHostKeyChecking=yes with a
              generated known_hosts), instead of trust-on-first-use.
            '';
          };
          allowOther = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Allow users other than the mounting user to access the FUSE mount.";
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
            ];
            description = "Extra options to pass to sshfs (-o). When knownHostKey is set, host-key checking options are added automatically.";
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.sshfs];

    programs.fuse.userAllowOther = true;

    systemd.services = lib.mapAttrs' (name: mountCfg: let
      hasIdentity = mountCfg.identityFile != null;
      pinHost = mountCfg.knownHostKey != null;

      # When a host key is pinned, write a known_hosts file and require it.
      knownHostsFile =
        pkgs.writeText "sshfs-${name}-known_hosts"
        "${mountCfg.host} ${mountCfg.knownHostKey or ""}\n";

      hostKeyOptions =
        if pinHost
        then [
          "StrictHostKeyChecking=yes"
          "UserKnownHostsFile=${knownHostsFile}"
        ]
        else [];

      # When pinning, drop any StrictHostKeyChecking from extraOptions so it
      # doesn't conflict with the pinned StrictHostKeyChecking=yes.
      baseOptions =
        if pinHost
        then lib.filter (o: !(lib.hasPrefix "StrictHostKeyChecking=" o)) mountCfg.extraOptions
        else mountCfg.extraOptions;

      options = lib.concatStringsSep "," (
        baseOptions
        ++ hostKeyOptions
        ++ lib.optional mountCfg.allowOther "allow_other"
        ++ lib.optional hasIdentity "IdentityFile=${mountCfg.identityFile}"
      );

      sshfsCmd = "${pkgs.sshfs}/bin/sshfs ${lib.escapeShellArgs ["${mountCfg.user}@${mountCfg.host}:${mountCfg.remotePath}" mountCfg.mountPoint "-p" (toString mountCfg.port) "-f" "-o" options]}";

      execStartCmd = sshfsCmd;
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
