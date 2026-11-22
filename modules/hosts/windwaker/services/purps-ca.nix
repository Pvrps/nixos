{
  config,
  lib,
  ...
}: let
  auth = config.sops.secrets."github-package-read-token".path;
in {
  sops.secrets."github-package-read-token".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers.purps-ca = lib.custom.mkContainer {
    tz = null;
    requiresMounts = false;
    containerConfig = {
      image = "ghcr.io/pvrps/purps.ca:latest";
      publishPorts = ["48080:3000"];
      # The login is needed twice over: to start the container, and for
      # podman-auto-update to look for a newer image.
      podmanArgs = ["--authfile=${auth}"];
      labels = ["io.containers.autoupdate.authfile=${auth}"];
    };
  };
}
