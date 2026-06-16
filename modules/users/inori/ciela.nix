{...}: {
  imports = [
    ./general.nix
    ./stylix.nix
    ./profiles/desktop.nix
    ./profiles/browsers.nix
    ./profiles/gaming.nix
    ./profiles/media.nix
    ./profiles/hardware.nix
  ];

  home.persistence."/persist" = {
    directories = [
      "Downloads"
      "Pictures"
      "Videos"
      "Documents"
    ];
  };
}
