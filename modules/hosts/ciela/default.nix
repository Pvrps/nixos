{config, ...}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./desktop.nix
    ./users.nix

    ../../../modules/nixos/core.nix
    ../../../modules/nixos/nvidia.nix
    ../../../modules/nixos/gaming.nix
    ../../../modules/nixos/beszel-agent.nix
    ../../../modules/nixos/tailscale.nix
  ];

  programs.nh = {
    enable = true;
  };

  networking.hostName = "ciela";

  custom = {
    gaming = {
      enable = true;
      steamRemotePlay.openFirewall = true;
      steamDedicatedServer.openFirewall = true;
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # SSH-key-only host — passwords are random and unknown, so wheel must not need one for sudo
  sops.defaultSopsFile = ./_secrets.yaml;

  security.sudo.wheelNeedsPassword = false;

  custom.services.beszel-agent = {
    enable = true;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQAj+3OR1B8cBF0GrVs1jmTuy5snr6zoRaK67v+j42D";
    tokenFile = config.sops.secrets."beszel-agent-token".path;
    hubUrl = "http://windwaker:8090";
    gpuMonitoring = true;
  };
}
