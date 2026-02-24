{pkgs, ...}: let
  sidecar = pkgs.buildGoModule {
    pname = "sidecar";
    version = "0.74.1";

    src = pkgs.fetchFromGitHub {
      owner = "marcus";
      repo = "sidecar";
      rev = "v0.74.1";
      hash = "sha256-kR75cLe8ZYcsG/tGunKf91l4E2g1MKEGcCfQNVyqk5I=";
    };

    vendorHash = "sha256-EwgUInjo7zpRX/Lc0dCsiBrNxW8Ki9QxAKBA6dvjX3M=";

    doCheck = false;
  };

  td = pkgs.buildGoModule {
    pname = "td";
    version = "0.38.0";

    src = pkgs.fetchFromGitHub {
      owner = "marcus";
      repo = "td";
      rev = "v0.38.0";
      hash = "sha256-PMSbdGBDMlrhqNH5DpTDAu721d0sMY0Dyk7ZTuHw3Ng=";
    };

    vendorHash = "sha256-8mOebFPbf7+hCpn9hUrE0IGu6deEPSujr+yHqrzYEec=";

    doCheck = false;
  };
in {
  home.packages = [sidecar td];
}
