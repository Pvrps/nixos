{
  config,
  lib,
  pkgs,
  ...
}: {
  options.custom.secureboot.enable = lib.mkEnableOption "Lanzaboote Secure Boot";

  config = lib.mkIf config.custom.secureboot.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    environment.systemPackages = [pkgs.sbctl];
  };
}
