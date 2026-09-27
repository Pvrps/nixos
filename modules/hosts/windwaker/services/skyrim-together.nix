# Skyrim Together Reborn dedicated server. Clients (navi, ciela) connect to
# 10.0.10.16:10578 over UDP. The server only relays and syncs state between
# clients (each player's game simulates its own world), so it's light enough
# for this box.
{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
  port = 10578;
in {
  virtualisation.quadlet.containers.skyrim-together = lib.custom.mkContainer {
    tz = null;
    containerConfig = {
      # MAINTENANCE: must match the clients' STR version. Pinned to an exact
      # tag so podman-auto-update leaves it alone; bump alongside the mod.
      image = "docker.io/tiltedphoques/st-reborn-server:1.8.2";
      publishPorts = ["${toString port}:${toString port}/udp"];
      # Upstream runs this with -it. Under systemd stdin is /dev/null, so give
      # the interactive console a TTY to keep it alive.
      podmanArgs = ["--tty"];
      volumes = [
        "${dockerVolumeDir}/skyrim-together/config:/st-server/config:U"
        "${dockerVolumeDir}/skyrim-together/Data:/st-server/Data:U"
        "${dockerVolumeDir}/skyrim-together/logs:/st-server/logs:U"
      ];
    };
  };

  # Same pattern as qbittorrent: explicit allow on the LAN interface.
  # tailscale0 is already in trustedInterfaces.
  networking.firewall.interfaces."eno1".allowedUDPPorts = [port];
}
