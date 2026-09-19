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
      # gamemode: required by the polkit rule shipped in the gamemode package
      # (share/polkit-1/rules.d/gamemode.rules) which only grants the
      # governor/gpu/cpu/procsys helpers to members of this group. Without it
      # gamemoded's pkexec calls fail with "Not authorized" and every game
      # silently loses the CPU governor and split-lock optimisations.
      extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "hardware-control" "tailscale" "gamemode"];
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
        "chatterino7-kick-client"
        "chatterino7-kick-secret"
      ];
    };
}
