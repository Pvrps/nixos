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
        # docker group: manage containers without sudo
        # wheel: sudo for anything requiring root
        extraGroups = ["wheel" "docker" "networkmanager" "video" "audio" "input"];
        shell = pkgs.fish;
        hashedPasswordFile = config.sops.secrets."purps-password".path;
        # TODO: add your SSH public key here before running install.sh
        # openssh.authorizedKeys.keys = [
        #   "ssh-ed25519 AAAA... purps@yourmachine"
        # ];
      };

      root = {
        hashedPassword = "!"; # password login disabled; SSH key only
        # TODO: add your SSH public key here before running install.sh
        # openssh.authorizedKeys.keys = [
        #   "ssh-ed25519 AAAA... purps@yourmachine"
        # ];
      };
    };
  };

  sops = {
    age.keyFile = "/persist/system/sops/age/keys.txt";
    secrets = {
      "purps-password" = {
        neededForUsers = true;
      };

      # Added post-install via `just secrets windwaker`
      # Provides the GitHub SSH private key path to purps/general.nix
      "github-ssh-key" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };
    };
  };
}
