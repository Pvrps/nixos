{
  config,
  lib,
  ...
}: let
  dockerVolumeDir = "/mnt/docker";
in {
  sops.secrets."rustdesk-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers = {
    tailscale-rustdesk = lib.custom.mkContainer {
      tz = null;
      containerConfig = {
        image = "tailscale/tailscale:latest";
        addCapabilities = [
          "NET_ADMIN"
          "NET_RAW"
        ];
        devices = ["/dev/net/tun:/dev/net/tun"];
        environmentFiles = [config.sops.secrets."rustdesk-env".path];
        environments = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_USERSPACE = "false";
          TS_HOSTNAME = "rustdesk";
        };
        publishPorts = [
          "21115:21115/tcp"
          "21116:21116/tcp"
          "21116:21116/udp"
          "21117:21117/tcp"
          "21118:21118/tcp"
          "21119:21119/tcp"
        ];
        volumes = [
          "${dockerVolumeDir}/tailscale-rustdesk:/var/lib/tailscale"
        ];
      };
    };

    # hbbs and hbbr share the tailscale-rustdesk network namespace.
    # Quadlet does not have a first-class option for --network=container:,
    # so it is passed through podmanArgs. No publishPorts here — traffic
    # flows through the tailscale-rustdesk container's network stack.
    # networks=[] because the netns is inherited via podmanArgs.
    hbbs = lib.custom.mkContainer {
      networks = [];
      containerConfig = {
        image = "rustdesk/rustdesk-server:latest";
        exec = "hbbs";
        podmanArgs = ["--network=container:tailscale-rustdesk"];
        volumes = [
          "${dockerVolumeDir}/rustdesk:/root"
        ];
      };
      unitConfig = {
        After = ["tailscale-rustdesk.service"];
        Requires = ["tailscale-rustdesk.service"];
      };
    };

    hbbr = lib.custom.mkContainer {
      networks = [];
      containerConfig = {
        image = "rustdesk/rustdesk-server:latest";
        exec = "hbbr";
        podmanArgs = ["--network=container:tailscale-rustdesk"];
        volumes = [
          "${dockerVolumeDir}/rustdesk:/root"
        ];
      };
      unitConfig = {
        After = [
          "tailscale-rustdesk.service"
          "hbbs.service"
        ];
        Requires = [
          "tailscale-rustdesk.service"
          "hbbs.service"
        ];
      };
    };
  };
}
