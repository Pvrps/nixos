{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./desktop.nix
    ./users.nix

    ../../../modules/nixos/core.nix
    ../../../modules/nixos/nvidia.nix
    ../../../modules/nixos/gaming.nix
    ../../../modules/nixos/services/sshfs.nix
    ../../../modules/nixos/tailscale.nix
    ../../../modules/nixos/secureboot.nix
  ];

  networking.hostName = "desktop";
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [5173];

  custom.services.sshfs = {
    enable = true;
    mounts = {
      windwaker = {
        host = "10.0.10.16";
        user = "root";
        identityFile = config.sops.secrets."sftp-windwaker-key".path;
        mountPoint = "/mnt/windwaker";
      };
    };
  };

  sops.defaultSopsFile = ./_secrets.yaml;
}
