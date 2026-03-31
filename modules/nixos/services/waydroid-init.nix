{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.virtualisation.waydroid.enable {
    systemd.services.waydroid-init = {
      description = "Initialize Waydroid with GAPPS";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        export PATH=$PATH:${pkgs.coreutils}/bin
        if [ ! -d "/var/lib/waydroid/images" ] || [ -z "$(ls -A /var/lib/waydroid/images)" ]; then
          echo "Initializing Waydroid with GAPPS..."
          ${pkgs.waydroid}/bin/waydroid init -s GAPPS
        else
          echo "Waydroid is already initialized."
        fi
      '';
    };
  };
}
