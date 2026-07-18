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
      # docker group: manage containers without sudo
      # wheel: sudo for anything requiring root
      extraGroups = ["wheel" "docker" "networkmanager" "video" "audio" "input"];
      shell = pkgs.fish;
      hashedPassword = "!"; # SSH-key-only login
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKXahrPYpFxiNEPA+IFJYRnn6DwABTtHy0H26HkoWbEw purps@navi"
      ];
    };

    podman-admin = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = ["docker" "podman"];
      shell = pkgs.bash;
      hashedPasswordFile = config.sops.secrets."podman-admin-password".path;
    };
  };

  sops.secrets =
    {"podman-admin-password".neededForUsers = true;}
    # Added post-install via `just secrets windwaker`
    // lib.custom.mkUserSecrets {
      owner = "purps";
      secrets = ["github-ssh-key"];
    };
}
