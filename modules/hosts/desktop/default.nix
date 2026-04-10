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
  ];

  networking.hostName = "desktop";
  networking.firewall.allowedTCPPorts = [5173];

  services.teamviewer.enable = true;

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

  sops.defaultSopsFile = ./_secrets.yaml;
}
