{config, ...}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix
    ./desktop.nix
    ./users.nix

    ../../modules/nixos/core.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/services/sshfs.nix
  ];

  networking.hostName = "desktop";
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
