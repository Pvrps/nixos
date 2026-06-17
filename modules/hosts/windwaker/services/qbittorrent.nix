{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
  torrentingPort = 48150;
in {
  # Ensure correct ownership so the container (UID/GID 1000) can write downloads.
  systemd.tmpfiles.rules = [
    "d ${dockerVolumeDir}/qbittorrent/torrents 0755 1000 1000 -"
    "d ${dockerVolumeDir}/qbittorrent/config   0755 1000 1000 -"
  ];

  virtualisation.quadlet.containers.qbittorrent = lib.custom.mkContainer {
    containerConfig = {
      image = "ghcr.io/linuxserver/qbittorrent:latest";
      publishPorts = [
        "24535:8080"                             # WebUI (internal 8080 -> host 24535)
        "${toString torrentingPort}:${toString torrentingPort}/tcp"
        "${toString torrentingPort}:${toString torrentingPort}/udp"
      ];
      volumes = [
        "${dockerVolumeDir}/qbittorrent/config:/config"
        "${dockerVolumeDir}/qbittorrent/torrents:/downloads"
      ];
      environments = {
        PUID = "1000";
        PGID = "1000";
        WEBUI_PORT = "8080";
        TORRENTING_PORT = toString torrentingPort;
      };
    };
  };

  # Open the torrenting port on the LAN interface for incoming peer connections.
  # Forward TCP+UDP 48150 on your router to 10.0.10.16.
  networking.firewall.interfaces."eno1".allowedTCPPorts = [torrentingPort];
  networking.firewall.interfaces."eno1".allowedUDPPorts = [torrentingPort];
}
