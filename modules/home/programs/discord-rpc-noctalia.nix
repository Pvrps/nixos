{
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.discordRpcNoctalia;
in {
  options.custom.programs.discordRpcNoctalia = {
    enable = lib.mkEnableOption "Noctalia bar widget + panel for Discord RPC management";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.discordRpc.enable;
        message = "custom.programs.discordRpcNoctalia requires custom.programs.discordRpc.enable = true.";
      }
      {
        assertion = config.custom.programs.noctalia.enable;
        message = "custom.programs.discordRpcNoctalia requires custom.programs.noctalia.enable = true.";
      }
    ];

    # ── Deploy QML plugin files ───────────────────────────────────────────────
    # Placed as read-only symlinks via xdg.configFile. The bar widget ID is
    # injected declaratively in noctalia.nix because Noctalia's auto-add only
    # fires from the Settings UI toggle, not from a plugins.json pre-seed.
    xdg.configFile = {
      "noctalia/plugins/discord-rpc/manifest.json".source =
        ./discord-rpc-noctalia/manifest.json;

      "noctalia/plugins/discord-rpc/BarWidget.qml".source =
        ./discord-rpc-noctalia/BarWidget.qml;

      "noctalia/plugins/discord-rpc/Panel.qml".source =
        ./discord-rpc-noctalia/Panel.qml;
    };

    # ── Register plugin via the declarative noctalia plugins option ──────────
    # sourceUrl matches Noctalia's mainSourceUrl so the composite key is the
    # bare "discord-rpc" (no hash prefix), giving the stable bar widget ID
    # "plugin:discord-rpc" regardless of any future changes here.
    custom.programs.noctalia.plugins."discord-rpc" = {
      enable = true;
      barWidget = true;
    };
  };
}
