{pkgs, ...}: {
  # These settings are intentionally convenience-biased. Bluetooth pairing for
  # the 8BitDo Pro 2 controller was unreliable without them; revisit later.
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Experimental = true;
        JustWorksRepairing = "always";
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    gnome-bluetooth
    blueman
  ];
}
