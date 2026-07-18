{
  pkgs,
  config,
  lib,
  ...
}: {
  users.users = {
    purps = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "hardware-control" "tailscale"];
      shell = pkgs.fish;
      hashedPasswordFile = config.sops.secrets."purps-password".path;
    };
  };

  sops.secrets =
    {"purps-password".neededForUsers = true;}
    // lib.custom.mkUserSecrets {
      owner = "purps";
      secrets = [
        "ciela-purps-key"
        "windwaker-purps-key"
        "mickey-purps-key"
        "github-ssh-key"
        "github-token"
        "context7-api-key"
        "rustdesk-server"
        "rustdesk-key"
      ];
    };
}
