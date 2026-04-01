{pkgs, ...}: {
  home = {
    username = "mike";
    homeDirectory = "/home/mike";
    stateVersion = "26.05";

    file."Desktop/Shutdown.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Shutdown
        Comment=Power off the computer
        Exec=systemctl poweroff
        Icon=system-shutdown
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/Sleep.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Sleep
        Comment=Suspend the computer
        Exec=systemctl suspend
        Icon=system-suspend
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/ConnectedCare.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Connected Care
        Comment=Open Connected Care
        Exec=firefox https://connectedcare.mychamp.ca/Phm-PhmHome.HomePage.WR.mthr?hcis=CHMPGBL.LIVE&application=PHM
        Icon=kdesrc-build
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/MedicalVisits.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Medical Visits
        Comment=Open Medical Visits
        Exec=firefox https://epicapps.toh.ca/MyChart/Authentication/Login?postloginurl=Visits
        Icon=kdesrc-build
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/Gmail.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Gmail
        Comment=Open Gmail
        Exec=firefox https://mail.google.com
        Icon=internet-mail
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/YouTube.desktop" = {
      text = ''
        [Desktop Entry]
        Name=YouTube
        Comment=Open YouTube
        Exec=firefox https://www.youtube.com
        Icon=video-display
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/Google.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Google
        Comment=Open Google Search
        Exec=firefox https://www.google.com
        Icon=im-google
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/Scotiabank.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Scotiabank
        Comment=Open Scotiabank
        Exec=firefox https://www.scotiaonline.scotiabank.com/
        Icon=kmymoney
        Terminal=false
        Type=Application
      '';
      executable = true;
    };

    file."Desktop/ScatterSlots.desktop" = {
      text = ''
        [Desktop Entry]
        Name=Scatter Slots
        Comment=Open Scatter Slots
        Exec=firefox https://apps.facebook.com/scatterslots/?fb_source=appcenter
        Icon=preferences-desktop-gaming
        Terminal=false
        Type=Application
      '';
      executable = true;
    };
  };

  custom.programs = {
    firefox = {
      enable = true;
      homepage = "https://www.google.com";
      profiles.mike = {
        id = 0;
        name = "mike";
        isDefault = true;
      };
      extensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
    rustdesk.enable = true;
  };
}
