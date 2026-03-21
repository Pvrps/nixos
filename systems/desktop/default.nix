{config, ...}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix

    ../../modules/nixos/core.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/services/sshfs.nix
  ];

  networking.firewall.allowedTCPPorts = [5173];

  custom.services.sshfs = {
    enable = true;
    mounts = {
      windwaker = {
        host = "10.0.10.16";
        user = "root";
        passwordSecret = config.sops.secrets."sftp-windwaker-password".path;
        mountPoint = "/mnt/windwaker";
      };
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;
}
