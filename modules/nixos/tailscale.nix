# Tailscale VPN. Enabled by default on every host; opt out per-host if needed.
{
  config,
  lib,
  ...
}: {
  options.custom.tailscale.enable = lib.mkEnableOption "Tailscale VPN" // {default = true;};

  config = lib.mkIf config.custom.tailscale.enable {
    services.tailscale.enable = true;
  };
}
