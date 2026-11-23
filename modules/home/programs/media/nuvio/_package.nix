# Nuvio desktop: upstream's release AppImage (a jpackage'd Compose app with
# its own JRE), wrapped with appimageTools. Not in nixpkgs or on Flathub.
#
# The AppImage doesn't bundle its native playback libraries: libmpv (loaded
# via JNA) and GStreamer for the built-in player. appimageTools already
# provides GStreamer core/base/ugly and SDL2; extraPkgs adds the rest.
#
# Underscore prefix: import-tree skips this file; nuvio.nix callPackages it.
{
  appimageTools,
  fetchurl,
}: let
  pname = "nuvio";
  # MAINTENANCE: release AppImage pin, see MAINTENANCE.md
  version = "0.1.38-alpha";
in
  appimageTools.wrapType2 (finalAttrs: {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/NuvioMedia/NuvioDesktop/releases/download/${version}/Nuvio-Linux-x86_64-${version}.AppImage";
      hash = "sha256-TvzQV1xsuMISiVIJMndm+nbp3N2d2GMCO5zkRfamEM0=";
    };

    extraPkgs = pkgs: [
      pkgs.mpv-unwrapped # libmpv playback engine
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-libav
    ];

    extraInstallCommands = ''
      install -Dm444 ${finalAttrs.contents}/Nuvio.desktop $out/share/applications/nuvio.desktop
      install -Dm444 ${finalAttrs.contents}/Nuvio.png $out/share/icons/hicolor/256x256/apps/Nuvio.png
      substituteInPlace $out/share/applications/nuvio.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=nuvio'
    '';
  })
