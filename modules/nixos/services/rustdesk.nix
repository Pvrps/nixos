{ config, lib, pkgs, ... }:

{
  options.services.rustdesk-relay.enable = lib.mkEnableOption "RustDesk relay (non-root)";

  config = lib.mkIf config.services.rustdesk-relay.enable {
    users.users.rustdesk = {
      isSystemUser = true;
      group        = "rustdesk";
      description  = "RustDesk relay daemon";
    };
    users.groups.rustdesk = {};

    systemd.services.rustdesk = {
      description = "RustDesk relay";
      after       = [ "network.target" ];
      wantedBy    = [ "multi-user.target" ];
      serviceConfig = {
        User   = "rustdesk";
        Group  = "rustdesk";
        ExecStart = "${pkgs.rustdesk-server}/bin/hbbr";
        Restart   = "always";
        RestartSec = "5s";
        NoNewPrivileges        = true;
        ProtectSystem          = "strict";
        ProtectHome            = true;
        PrivateTmp             = true;
        PrivateDevices         = true;
        ProtectKernelTunables  = true;
        ProtectKernelModules   = true;
        ProtectControlGroups   = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces     = true;
        LockPersonality        = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime       = true;
        SystemCallFilter       = [ "@system-service" ];
      };
    };
  };
}
