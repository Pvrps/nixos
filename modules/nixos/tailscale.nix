{ config, lib, ... }: {
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}