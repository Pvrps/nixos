{...}: {
  imports = [
    ./general.nix
    ./profiles/desktop.nix
    ./profiles/browsers.nix
    ./profiles/dev.nix
    ./profiles/gaming.nix
    ./profiles/media.nix
    ./profiles/hardware.nix
  ];

  custom.programs.ssh.extraHosts = {
    "windwaker" = {
      HostName = "10.0.10.16";
      User = "purps";
      IdentityFile = "~/.ssh/id_ed25519_windwaker_purps";
    };
    "windwaker-root" = {
      HostName = "10.0.10.16";
      User = "root";
      IdentityFile = "~/.ssh/id_ed25519_windwaker_root";
    };
  };
}
