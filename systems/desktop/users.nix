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
        extraGroups = ["wheel" "networkmanager" "video" "audio" "input"];
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
      "sftp-windwaker-password" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };
    };
  };
}
