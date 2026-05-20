{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.okular;
in {
  options.custom.programs.okular.enable = lib.mkEnableOption "Okular document viewer";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs.kdePackages; [
      okular
    ];

    xdg.mimeApps.defaultApplications = {
      "application/pdf" = "okularApplication_pdf.desktop";
      "application/x-gzpdf" = "okularApplication_pdf.desktop";
      "application/x-bzpdf" = "okularApplication_pdf.desktop";
      "application/x-wwf" = "okularApplication_pdf.desktop";
    };
  };
}
