{osConfig, ...}: {
  custom.programs = {
    stremio.enable = true;
    clapper.enable = true;
    rustdesk = {
      enable = true;
      serverFile = osConfig.sops.secrets."rustdesk-server".path;
      keyFile = osConfig.sops.secrets."rustdesk-key".path;
    };
    flatpak = {
      enable = true;
      packages = [
        "com.github.tchx84.Flatseal"
      ];
    };
    obs = {
      enable = true;
      plugins = {
        aitumStreamSuite = {
          enable = true;
          version = "1.1.2";
          hash = "sha256:46137e8ec8b92704879c58ed486bede468102935e53d25f3f1a36a5e07c71bca";
        };
        pipewireAudioCapture = {
          enable = true;
          version = "1.2.1";
          hash = "sha256:e3bfa510bf3cfccdba092ee726e7e0d3cbe433dd49d4101f6a3e2b7fa68eae84";
        };
      };
    };
    spotify.enable = true;
    okular.enable = true;
    pinta.enable = true;
  };
}
