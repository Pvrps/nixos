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
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXahrPYpFxiNEPA+IFJYRnn6DwABTtHy0H26HkoWbEw purps@desktop"
        ];
      };

      podman-admin = {
        isNormalUser = true;
        uid = 1001;
        extraGroups = [ "docker" "podman" ];
        shell = pkgs.bash;
        hashedPasswordFile = config.sops.secrets."podman-admin-password".path;
      };

      root = {
        hashedPassword = "!"; # password login disabled; SSH key only
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP1ja+8eNXLnaCJ418HETeJKE9MbGWxCkuISufkbVMmh purps@desktop"
        ];
      };
    };
  };

  sops = {
    age.keyFile = "/persist/system/sops/age/keys.txt";
    secrets = {
      "purps-password" = {
        neededForUsers = true;
      };

      "podman-admin-password" = {
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
