{ pkgs, ... }: {
  home.packages = with pkgs; [
    clapper
  ];

  xdg.mimeApps.defaultApplications = {
    "video/mp4" = "com.github.rafostar.Clapper.desktop";
    "video/webm" = "com.github.rafostar.Clapper.desktop";
    "video/x-matroska" = "com.github.rafostar.Clapper.desktop";
    "video/quicktime" = "com.github.rafostar.Clapper.desktop";
  };
}
