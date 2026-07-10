{config, ...}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./desktop.nix
    ./users.nix

    ../../../modules/nixos/nvidia.nix
    ../../../modules/nixos/gaming.nix
    ../../../modules/nixos/audio.nix
    ../../../modules/nixos/flatpak.nix
    ../../../modules/nixos/bluetooth.nix
    ../../../modules/nixos/hardware-control.nix
    ../../../modules/nixos/opentabletdriver.nix
    ../../../modules/nixos/services/sshfs.nix
    ../../../modules/nixos/beszel-agent.nix
    ../../../modules/nixos/secureboot.nix
  ];

  # roc-toolkit mic stream from ciela (Inori) — receiver ports for the RTP
  # source/repair/control endpoints, scoped to the tailscale interface only.
  networking.firewall.interfaces."tailscale0".allowedUDPPorts = [10001 10002 10003];

  custom = {
    audio.lowLatency.enable = true;
    flatpak.enable = true;

    opentabletdriver.enable = true;

    bluetooth = {
      enable = true;
      guiTools = true;
    };

    hardwareControl = {
      enable = true;
      motherboard = "amd";
      liquidctl = true;
    };

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
          user = "purps";
          remotePath = "/mnt/";
          identityFile = config.sops.secrets."windwaker-purps-key".path;
          mountPoint = "/mnt/windwaker";
          allowOther = true;
          knownHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzhmSCILV7cN4qukQz50I2YpEsPiT6DfsJiPdLf9pUr";
        };
      };
    };
  };

  custom.services.beszel-agent = {
    enable = true;
    key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQAj+3OR1B8cBF0GrVs1jmTuy5snr6zoRaK67v+j42D";
    tokenFile = config.sops.secrets."beszel-agent-token".path;
    hubUrl = "http://windwaker:8090";
    gpuMonitoring = true;
  };
}
