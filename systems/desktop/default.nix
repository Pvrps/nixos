{ pkgs, inputs, config, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;

  time.timeZone = "America/New_York"; # Change this
  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = false;
  users.users.purps = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.fish;
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
  users.users.purps.hashedPasswordFile = config.sops.secrets."purps-password".path;
  users.users.root.initialPassword = "changeme";

  programs.fish.enable = true;
  programs.niri.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;
  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
      user = "greeter";
    };
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
  };

  environment.systemPackages = [
    pkgs.xwayland-satellite
  ];

  system.stateVersion = "24.11";
}
