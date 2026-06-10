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

  custom.scripts.capture.ocr.enable = true;

  custom.programs.ssh = {
    windwakerPurpsKeyPath = osConfig.sops.secrets."windwaker-purps-key".path;
    windwakerRootKeyPath = osConfig.sops.secrets."windwaker-root-key".path;
    extraHosts = {
      "windwaker" = {
        HostName = "10.0.10.16";
        User = "purps";
        IdentityFile = osConfig.sops.secrets."windwaker-purps-key".path;
      };
      "windwaker-root" = {
        HostName = "10.0.10.16";
        User = "root";
        IdentityFile = osConfig.sops.secrets."windwaker-root-key".path;
      };
    };
  };
}
