{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix
    ./stylix.nix
    ./microphone.nix
  ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };
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

  time.timeZone = "America/New_York"; # Change this
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

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
    upower.enable = true;
    xserver.videoDrivers = ["nvidia"];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = [
        "https://nix-community.cachix.org"
        "https://mic92.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "mic92.cachix.org-1:vL3/V4C9t6xBFZ8c4hA29EfGaKjXcruzjxj815V/V24="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  environment.systemPackages = [
  ];

  system.stateVersion = "24.11";
}
