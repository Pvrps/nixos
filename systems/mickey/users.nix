{
  pkgs,
  config,
  ...
}: {
  programs.fish.enable = true;

  users = {
    mutableUsers = false;
    users = {
      michel = {
        isNormalUser = true;
        extraGroups = ["networkmanager" "video" "audio" "input"];
        hashedPasswordFile = config.sops.secrets."michel-password".path;
      };
      purps = {
        isNormalUser = true;
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
      "michel-password" = {
        neededForUsers = true;
      };
    };
  };
}
