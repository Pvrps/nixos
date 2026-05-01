{
  inputs,
  pkgs,
  ...
}: {
  # uinput is required for Steam Input to create virtual controller devices
  boot.kernelModules = ["uinput"];



  # uinput must be writable by the input group for Steam Input to create virtual devices
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  # xpadneo: advanced Xbox/8BitDo BT driver, fixes GET_REPORT timeouts and ERTM issues
  hardware.xpadneo.enable = true;

  programs = {
    steam = {
      enable = true;
      package = inputs.millennium.packages.${pkgs.system}.millennium-steam;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    gamemode.enable = true;
    gamescope.enable = true;
  };
}
