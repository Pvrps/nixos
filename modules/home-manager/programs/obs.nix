{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.obs;
  inherit (config.custom) obs;

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
    lib.optionalAttrs obs.plugins.multiRtmp.enable
    (mkPlugin {
      name = "obs-multi-rtmp";
      src = pkgs.fetchurl {
        url = "https://github.com/sorayuki/obs-multi-rtmp/releases/download/${obs.plugins.multiRtmp.version}/obs-multi-rtmp-0.7.3.0-x86_64-linux-gnu.deb";
        inherit (obs.plugins.multiRtmp) hash;
      };
    });
in {
  options.custom.programs.obs.enable = lib.mkEnableOption "OBS Studio via Flatpak with plugin management";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.obs requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.flatpak.packages = lib.mkAfter ["com.obsproject.Studio"];

    home.file = pluginFiles;
  };
}
