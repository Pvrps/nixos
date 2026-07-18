{
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./session.nix
    ./users.nix
  ];

  custom = {
    profiles.workstation.enable = true;
    desktop.portals.backend = "kde";
    remoteAdmin.enable = true;
  };
}
