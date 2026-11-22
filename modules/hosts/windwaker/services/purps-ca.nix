{
  config,
  lib,
  pkgs,
  ...
}: let
  # The image is private, so pulling it takes a login. The secret is a GitHub
  # token which can only read packages. Podman wants a login file rather than a
  # bare token, so one is made from it each time the container starts, and is
  # gone again when it stops.
  token = config.sops.secrets."github-package-read-token".path;
  auth = "/run/purps-ca/auth.json";

  login = pkgs.writeShellScript "purps-ca-login" ''
    exec ${config.virtualisation.podman.package}/bin/podman login \
      --authfile ${auth} --username pvrps --password-stdin ghcr.io < ${token}
  '';
in {
  sops.secrets."github-package-read-token".sopsFile = ./_secrets.yaml;

  # The sites under purps.ca, all served by one app which picks a site by the
  # name it was asked for (https://github.com/Pvrps/purps.ca).
  #
  # The image is published when a release is tagged there. The :latest tag
  # moves with each release, so podman-auto-update picks new ones up by itself.
  # To take one straight away: `systemctl start podman-auto-update`.
  #
  # In NPM, point purps.ca and osu.purps.ca at 10.0.10.16:48080 (scheme http).
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
    serviceConfig = {
      RuntimeDirectory = "purps-ca";
      RuntimeDirectoryMode = "0700";
      ExecStartPre = login;
    };
  };
}
