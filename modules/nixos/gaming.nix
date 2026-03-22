{ inputs, pkgs, ... }: {
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
