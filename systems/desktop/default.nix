{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix
    ./stylix.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelParams = ["nvidia-drm.modeset=1"];
  };

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  hardware = {
    bluetooth.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      open = false;
    };
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  users = {
    mutableUsers = false;
    users = {
      purps = {
        isNormalUser = true;
        extraGroups = ["wheel" "networkmanager" "video" "audio" "input"];
        shell = pkgs.fish;
        hashedPasswordFile = config.sops.secrets."purps-password".path;
      };
      root.hashedPassword = "!";
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/persist/system/sops/age/keys.txt";
    secrets = {
      "purps-password" = {
        neededForUsers = true;
      };

      "github-ssh-key" = {
        owner = "purps";
        group = "users";
        mode = "0600";
      };
    };
  };

  programs = {
    fish.enable = true;
    niri.enable = true;
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    gamemode.enable = true;
    gamescope.enable = true;
  };

  security = {
    pam.services.greetd.enableGnomeKeyring = true;
    rtkit.enable = true;
  };

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 2048;
        };
      };
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
        user = "greeter";
      };
    };
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
    flatpak.enable = true;
    xserver.videoDrivers = ["nvidia"];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gnome];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = [
        "https://nix-community.cachix.org"
        "https://mic92.cachix.org"
        "https://cache.numtide.com"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "mic92.cachix.org-1:vL3/V4C9t6xBFZ8c4hA29EfGaKjXcruzjxj815V/V24="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };

  environment = {
    systemPackages = with pkgs; [
      seahorse
      nvidia-vaapi-driver
      libva-utils
    ];
    sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      PROTON_ENABLE_NVAPI = "1";
    };
  };

  system.stateVersion = "26.05";
}
