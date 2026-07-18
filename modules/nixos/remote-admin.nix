# SSH server + passwordless sudo for wheel. For hosts administered remotely
# over SSH keys, where local account passwords are random and unknown.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.remoteAdmin;
in {
  options.custom.remoteAdmin = {
    enable = lib.mkEnableOption "SSH server and passwordless sudo for wheel";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open port 22 on all interfaces. Set false to manage firewall rules per-interface in the host.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      inherit (cfg) openFirewall;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };

    # SSH-key-only hosts — passwords are random and unknown, so wheel must
    # not need one for sudo.
    security.sudo.wheelNeedsPassword = false;
  };
}
