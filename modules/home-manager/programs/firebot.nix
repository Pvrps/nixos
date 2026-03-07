{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.firebot;

  firebot-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "firebot";
    version = "5.65.4";

    src = pkgs.fetchurl {
      url = "https://github.com/crowbartools/Firebot/releases/download/v${version}/firebot-v${version}-linux-x64.tar.gz";
      hash = "sha256-C9dOvyt/34vQGwBbYzDXNVy7as/7mROGA+ztyi+5q7M=";
    };

    sourceRoot = ".";

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
            mkdir -p $out/opt/firebot
            cp -r * $out/opt/firebot/

            mkdir -p $out/bin

            echo "#!/bin/sh" > $out/bin/firebot
            echo "export NIXOS_OZONE_WL=1" >> $out/bin/firebot
            echo "export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [pkgs.nspr pkgs.nss pkgs.xorg.libXtst pkgs.mesa pkgs.libGL pkgs.alsa-lib pkgs.gtk3 pkgs.libdrm pkgs.xorg.libXdamage pkgs.xorg.libxshmfence]}:\$LD_LIBRARY_PATH" >> $out/bin/firebot
            echo "exec ${pkgs.steam-run}/bin/steam-run \"$out/opt/firebot/Firebot v5\" --enable-features=UseOzonePlatform --ozone-platform=wayland \"\$@\"" >> $out/bin/firebot

            chmod +x $out/bin/firebot

            # Install icons
            for size in 16 24 32 48 64 96 128 256 512; do
              mkdir -p $out/share/icons/hicolor/''${size}x''${size}/apps
              cp resources/linux/firebotsetup-icon/''${size}x''${size}.png $out/share/icons/hicolor/''${size}x''${size}/apps/firebot.png
            done

            # Install desktop file
            mkdir -p $out/share/applications
            cat > $out/share/applications/firebot.desktop << DESKTOP
      [Desktop Entry]
      Name=Firebot
      Exec=$out/bin/firebot
      Icon=firebot
      Terminal=false
      Type=Application
      Categories=Network;Chat;
      DESKTOP
    '';
  };
in {
  options.custom.programs.firebot.enable = lib.mkEnableOption "Firebot Twitch bot";

  config = lib.mkIf cfg.enable {
    home.packages = [firebot-pkg];
  };
}
