{
  pkgs,
  config,
  lib,
  ...
}: {
  users.users = {
    mike = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = ["networkmanager" "video" "audio" "input"];
      hashedPasswordFile = config.sops.secrets."mike-password".path;
    };

    purps = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "tailscale"];
      shell = pkgs.fish;
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC6oz9GSx/BDWu4m6gfaBh8QJUsoc3I86kYWX0W151UD purps@navi"
      ];
    };
  };

  sops.secrets =
    {"mike-password".neededForUsers = true;}
    // lib.custom.mkUserSecrets {
      owner = "purps";
      secrets = ["github-ssh-key" "rustdesk-server"];
    }
    // lib.custom.mkUserSecrets {
      owner = "root";
      group = "root";
      secrets = ["rustdesk-key" "rustdesk-password"];
    };
}
