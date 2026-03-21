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
    "${base}/data/locale".source = "${extracted}/usr/share/obs/obs-plugins/${name}/locale";
  };

  pluginFiles =
    lib.optionalAttrs cfg.plugins.multiRtmp.enable
    (mkPlugin {
      name = "obs-multi-rtmp";
      src = pkgs.fetchurl {
        url = "https://github.com/sorayuki/obs-multi-rtmp/releases/download/${cfg.plugins.multiRtmp.version}/obs-multi-rtmp-0.7.3.0-x86_64-linux-gnu.deb";
        inherit (cfg.plugins.multiRtmp) hash;
      };
    });
in {
  options.custom = {
    programs.obs = {
      enable = lib.mkEnableOption "OBS Studio via Flatpak with plugin management";
      plugins = {
        multiRtmp = {
          enable = lib.mkEnableOption "obs-multi-rtmp multistream plugin";
          version = lib.mkOption {
            type = lib.types.str;
            default = "0.7.3.2";
            description = "GitHub release tag for obs-multi-rtmp";
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

    home.file = pluginFiles;
  };
}
