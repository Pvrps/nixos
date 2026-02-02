{ ... }:
{
  programs.git = {
    enable = true;
    userName = "purps";
    userEmail = "github@purps.ca";
    extraConfig = {
      safe.directory = "/persist/etc/nixos";
    };
    #settings = {
    #  user = {
    #    name = "purps";
    #    email = "github@purps.ca";
    #  };
    #  safe.directory = "/persist/etc/nixos";
    #};
  };
}
