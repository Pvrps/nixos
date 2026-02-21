_: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix

    ../../modules/nixos/custom.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/desktop.nix
  ];

  sops.defaultSopsFile = ./secrets.yaml;
}
