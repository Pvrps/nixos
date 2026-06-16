{osConfig, ...}: {
  imports = [
    ./general.nix
    ./stylix.nix
    ./profiles/desktop.nix
    ./profiles/browsers.nix
    ./profiles/dev.nix
    ./profiles/gaming.nix
    ./profiles/media.nix
    ./profiles/hardware.nix
  ];

  home.persistence."/persist" = {
    directories = [
      ".putty"
      "Downloads"
      "Pictures"
      "Videos"
      "Development"
      "Documents"
    ];
  };

  custom.scripts.capture.ocr.enable = true;

  custom.programs.ssh = {
    extraHosts = {
      "windwaker" = {
        HostName = "10.0.10.16";
        User = "purps";
        IdentityFile = osConfig.sops.secrets."windwaker-purps-key".path;
      };
      "ciela" = {
        HostName = "10.0.0.232";
        User = "purps";
        IdentityFile = osConfig.sops.secrets."ciela-purps-key".path;
      };
    };
  };
}
