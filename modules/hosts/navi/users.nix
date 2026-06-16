{
  pkgs,
  config,
  ...
}: {
  programs.fish.enable = true;

  users = {
    mutableUsers = false;
    users = {
      purps = {
        isNormalUser = true;
        uid = 1000;
        extraGroups = ["wheel" "networkmanager" "video" "audio" "input" "hardware-control" "tailscale"];
        shell = pkgs.fish;
        hashedPasswordFile = config.sops.secrets."purps-password".path;
      };
      root.hashedPassword = "!";
    };
  };

  sops = {
    age.keyFile = "/persist/system/sops/age/keys.txt";
    secrets = {
      "purps-password" = {
        neededForUsers = true;
      };

      "ciela-purps-key" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };
      "windwaker-purps-key" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };

      "github-ssh-key" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };

      "context7-api-key" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };
      "bravesearch-api-key" = {
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
        owner = "purps";
        group = "users";
        mode = "0600";
      };

      "beszel-agent-token" = {
        owner = "beszel-agent";
        group = "root";
        mode = "0600";
      };
    };
  };
}
