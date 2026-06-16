{
  pkgs,
  config,
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
      hashedPasswordFile = config.sops.secrets."purps-password".path;
    };
  };

  sops.secrets = {
    "purps-password" = {
      neededForUsers = true;
    };
    "mike-password" = {
      neededForUsers = true;
    };

    "github-ssh-key" = {
      owner = "purps";
      group = "users";
      mode = "0600";
    };

    "rustdesk-server" = {
      owner = "purps";
      group = "users";
      mode = "0600";
    };
    "rustdesk-key" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };
}
