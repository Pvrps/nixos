{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./users.nix

    ../../../modules/nixos/core.nix
    ../../../modules/nixos/tailscale.nix
    ../../../modules/nixos/services/rustdesk.nix
    ../../../modules/nixos/secureboot.nix
  ];

  networking.hostName = "mickey";

  boot.kernelPackages = pkgs.linuxPackages_hardened;

  #custom.secureboot.enable = true;

  # Enable Services
  services = {
    xserver = {
      enable = true;
      displayManager.setupCommands = ''
        # Force the login screen to 1080p so scaling is perfect and RustDesk doesn't choke on 4K
        CONNECTED_DISP=$(${pkgs.xorg.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.gawk}/bin/awk '{ print $1 }')
        if [ -n "$CONNECTED_DISP" ]; then
          ${pkgs.xorg.xrandr}/bin/xrandr --output "$CONNECTED_DISP" --mode 1920x1080 || true
        fi
      '';
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      settings = {
        Users = {
          HideUsers = "purps";
        };
      };
    };

    desktopManager.plasma6.enable = true;
    displayManager.defaultSession = "plasmax11";

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
      };
    };
  };

  services.rustdesk-relay.enable = true;

  sops.defaultSopsFile = ./_secrets.yaml;
}
