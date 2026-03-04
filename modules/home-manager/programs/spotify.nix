{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.custom.programs.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  options.custom.programs.spotify.enable = lib.mkEnableOption "Spotify with Spicetify (Stylix theming + spoofed premium features)";

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        shuffle
        volumePercentage
        hidePodcasts
      ];
    };

    # WirePlumber Lua script: uses mixer-api to intercept Spotify's own
    # pw_stream_set_control(VOLUME, 1.0) calls on each track change.
    # Spotify is a native PipeWire client (not PA-compat), so pipewire-pulse
    # quirks are ineffective; only a WirePlumber-level hook can intercept it.
    xdg.configFile."wireplumber/scripts/50-spotify-volume.lua".text = ''
      -- Prevent Spotify from resetting its stream volume to 100% on track change.
      -- Strategy:
      --   1. On stream creation: wait 300 ms (outlasts WirePlumber's state-restore
      --      and Spotify's own init) then apply TARGET_VOLUME.
      --   2. On subsequent volume changes: if the new value jumped to ≥95% and WE
      --      didn't cause it, treat it as Spotify's reset and revert.
      --      If the change is smaller (user adjusting), save it as the new target.

      local TARGET_VOLUME    = 0.4   -- initial target (40 %)
      local INIT_DELAY_MS    = 300   -- ms to wait after stream appears
      local REVERT_DELAY_MS  = 100   -- ms before reverting a bad change
      local DEBOUNCE_MS      = 300   -- ms to suppress our own "changed" echo

      local mixer_api = Plugin.find("mixer-api")
      if not mixer_api then
        Log.warning("50-spotify-volume: mixer-api plugin not found; " ..
          "ensure WirePlumber's built-in mixer-api component is enabled " ..
          "(check `wireplumber.components` in your system config)")
        return
      end

      -- per node-id state
      local desired   = {}   -- desired volume for each Spotify node
      local our_change = {}  -- true while WE are the ones changing the volume

      local function set_volume(id, vol)
        our_change[id] = true
        Core.timeout_add(DEBOUNCE_MS, function()
          our_change[id] = nil
          return false
        end)
        local ok, err = pcall(function()
          mixer_api:call("set-volume", id, { volume = vol, mute = false })
        end)
        if not ok then
          Log.warning("50-spotify-volume: set-volume failed for node " .. id .. ": " .. tostring(err))
        end
      end

      local nodes_om = ObjectManager {
        Interest {
          type = "node",
          Constraint { "media.class", "=", "Stream/Output/Audio" },
          Constraint { "application.process.binary", "=", "spotify" },
        },
        Interest {
          type = "node",
          Constraint { "media.class", "=", "Stream/Output/Audio" },
          Constraint { "application.name", "=", "Spotify" },
        }
      }

      nodes_om:connect("object-added", function(_, node)
        local id = node["bound-id"]
        desired[id] = TARGET_VOLUME
        -- Apply after INIT_DELAY_MS so we run after WirePlumber's state-restore
        -- and after Spotify's own initial Props update.
        Core.timeout_add(INIT_DELAY_MS, function()
          if desired[id] then
            set_volume(id, desired[id])
          end
          return false
        end)
      end)

      nodes_om:connect("object-removed", function(_, node)
        local id = node["bound-id"]
        desired[id]    = nil
        our_change[id] = nil
      end)

      -- Monitor all volume changes on Spotify nodes.
      mixer_api:connect("changed", function(_, id, props)
        if not desired[id]  then return end  -- not a Spotify node we track
        if our_change[id]   then return end  -- we caused this change, ignore
        if not props or not props.volume then return end

        local vol = props.volume
        if vol >= 0.95 then
          -- Looks like Spotify's "reset to 100%" — revert to our desired value.
          Core.timeout_add(REVERT_DELAY_MS, function()
            if desired[id] then
              set_volume(id, desired[id])
            end
            return false
          end)
        else
          -- Looks like a deliberate user adjustment — honour it.
          desired[id] = vol
        end
      end)

      nodes_om:activate()
    '';

    # Load the script and add belt-and-suspenders stream.rules so WirePlumber
    # also won't restore a previously-saved 100% volume from its state store.
    xdg.configFile."wireplumber/wireplumber.conf.d/50-spotify-volume.conf".text = ''
      wireplumber.components = [
        {
          name = "50-spotify-volume.lua"
          type = "script/lua"
        }
      ]

      stream.rules = [
        {
          matches = [
            { application.process.binary = "spotify" }
            { application.name = "Spotify" }
          ]
          actions = {
            update-props = {
              state.restore-props = false
            }
          }
        }
      ]
    '';
  };
}
