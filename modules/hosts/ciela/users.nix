{
  pkgs,
  config,
  lib,
  ...
}: {
  users.users = {
    inori = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = ["networkmanager" "video" "audio" "input" "hardware-control" "tailscale"];
      shell = pkgs.fish;
      hashedPasswordFile = config.sops.secrets."inori-password".path;
    };

    purps = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = ["wheel"];
      shell = pkgs.fish;
      hashedPassword = "!";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAXv49nmdpRIsAIHxrcDcvhDzxPGxKHzqjnKYg6Kn109 purps@navi"
      ];
    };
  };

  sops.secrets =
    {"inori-password".neededForUsers = true;}
    // lib.custom.mkUserSecrets {
      owner = "purps";
      secrets = ["github-ssh-key"];
    }
    // lib.custom.mkUserSecrets {
      owner = "inori";
      secrets = ["rustdesk-server" "rustdesk-key" "rustdesk-password"];
    };
}
