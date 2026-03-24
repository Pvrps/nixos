{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.obs;

  mkPlugin = {
    name,
    src,
  }: let
    extracted = pkgs.runCommand "obs-plugin-${name}" {} ''
      ${pkgs.dpkg}/bin/dpkg-deb -x ${src} $out
    '';
    base = ".var/app/com.obsproject.Studio/config/obs-studio/plugins/${name}";
  in {
    "${base}/bin/64bit/${name}.so".source = "${extracted}/usr/lib/x86_64-linux-gnu/obs-plugins/${name}.so";
    # Map the entire data directory instead of just locale, as modern plugins have UI assets
    "${base}/data".source = "${extracted}/usr/share/obs/obs-plugins/${name}";
  };

  aitumStreamSuiteFiles =
    lib.optionalAttrs cfg.plugins.aitumStreamSuite.enable
    (mkPlugin {
      name = "aitum-stream-suite";
      src = pkgs.fetchurl {
        url = "https://github.com/Aitum/obs-aitum-stream-suite/releases/download/${cfg.plugins.aitumStreamSuite.version}/aitum-stream-suite-linux-gnu.deb";
        inherit (cfg.plugins.aitumStreamSuite) hash;
      };
    });
in {
  options.custom = {
    programs.obs = {
      enable = lib.mkEnableOption "OBS Studio via Flatpak with plugin management";
      plugins = {
        aitumStreamSuite = {
          enable = lib.mkEnableOption "Aitum Stream Suite plugin";
          version = lib.mkOption {
            type = lib.types.str;
            default = "1.1.0";
            description = "GitHub release tag for aitum-stream-suite";
          };
          hash = lib.mkOption {
            type = lib.types.str;
            description = "SHA256 hash of the .deb release asset";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.obs requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.programs.flatpak.packages = lib.mkAfter ["com.obsproject.Studio"];

    home.file = lib.mkMerge [
      aitumStreamSuiteFiles
    ];
  };
}
