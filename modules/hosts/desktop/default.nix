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
    ../../../modules/nixos/beszel-agent.nix
    ../../../modules/nixos/tailscale.nix
    ../../../modules/nixos/secureboot.nix
  ];

  programs.nh = {
    enable = true;
  };

  networking.hostName = "desktop";

  custom = {
    gaming = {
      enable = true;
      steamRemotePlay.openFirewall = true;
      steamDedicatedServer.openFirewall = true;
    };

    #secureboot.enable = true;
    services.sshfs = {
      enable = true;
      mounts = {
        windwaker = {
          host = "10.0.10.16";
          user = "root";
          remotePath = "/mnt/";
          identityFile = config.sops.secrets."windwaker-root-key".path;
          mountPoint = "/mnt/windwaker";
          allowOther = true;
        };
      };
    };
  };

  sops.defaultSopsFile = ./_secrets.yaml;

  custom.services.beszel-agent = {
    enable = true;
    key = "";
    hubUrl = "https://beszel.windwaker.ca";
    gpuPackages = [pkgs.nvidia-smi];
  };
}
