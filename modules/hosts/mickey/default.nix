# Mickey: low-end kiosk-style desktop (Plasma X11) administered via RustDesk.
{
  config,
  inputs,
  pkgs,
  ...
}: {
  # WORKAROUND: Plasma 6.8 dropped X11; KDE stack held at 6.7, see WORKAROUNDS.md
  # Only kdePackages (Plasma, Frameworks, their Qt, SDDM) comes from the pinned
  # nixpkgs; kernel, Mesa, Xorg, Firefox, RustDesk etc. stay on the shared one.
  nixpkgs.overlays = [
    (final: prev: {
      inherit (inputs.nixpkgs-plasma-x11.legacyPackages.${prev.stdenv.hostPlatform.system}) kdePackages;
    })
  ];
  # The current plasma6 module no longer installs kwin-x11 (the plasmax11
  # session needs it); the pinned plasma-workspace still ships the session.
  environment.systemPackages = [pkgs.kdePackages.kwin-x11];

  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./users.nix
  ];

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [22 5600];

  systemd.timers.fwupd-refresh.enable = false;

  # Hardware video decode on the N150 iGPU (intel-media-driver = iHD VAAPI).
  # Offloads browser video decode from the 4 E-cores to the GPU.
  hardware.graphics = {
    enable = true;
    extraPackages = [pkgs.intel-media-driver];
  };

  custom = {
    audio.enable = true;

    remoteAdmin = {
      enable = true;
      openFirewall = false; # SSH reachable via tailscale only (see above)
    };

    #secureboot.enable = true;

    services.rustdesk = {
      enable = true;
      serverFile = config.sops.secrets."rustdesk-server".path;
      keyFile = config.sops.secrets."rustdesk-key".path;
      passwordFile = config.sops.secrets."rustdesk-password".path;
    };
  };

  services = {
    xserver = {
      enable = true;
      displayManager.setupCommands = ''
        # Force the login screen to 1080p so scaling is perfect and RustDesk doesn't choke on 4K
        CONNECTED_DISP=$(${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep " connected" | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.gawk}/bin/awk '{ print $1 }')
        if [ -n "$CONNECTED_DISP" ]; then
          ${pkgs.xrandr}/bin/xrandr --output "$CONNECTED_DISP" --mode 1920x1080 || true
        fi
        # Grant root access to the display so the RustDesk system service can attach
        ${pkgs.xhost}/bin/xhost +SI:localuser:root
      '';
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = false;
      settings.Users.HideUsers = "purps";
    };

    desktopManager.plasma6.enable = true;
    displayManager.defaultSession = "plasmax11";
  };
}
