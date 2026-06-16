# Custom helper library, mixed into nixpkgs lib as lib.custom.* (see flake.nix).
# Available in every NixOS and home-manager module via the `lib` argument.
#
# Usage from a module:
#   { lib, pkgs, ... }:
#   lib.custom.mkScript { inherit pkgs; ... }
#
# Pure with respect to nixpkgs: helpers that produce derivations (mkScript)
# receive `pkgs` from the calling module's own arguments.
{lib}: rec {
  # ---------------------------------------------------------------------------
  # mkRequireWayland: standard assertion that a Wayland compositor is active.
  # Replaces the verbatim assertion block duplicated across terminal/script
  # modules. Needs `config` to read custom.system.wayland.enable.
  #
  #   config = lib.mkIf cfg.enable {
  #     assertions = [ (lib.custom.mkRequireWayland config "ocr") ];
  #   };
  # ---------------------------------------------------------------------------
  mkRequireWayland = config: name: {
    assertion = config.custom.system.wayland.enable;
    message = "${name} requires a Wayland compositor (custom.system.wayland.enable).";
  };

  # ---------------------------------------------------------------------------
  # mkScript: collapse the repeated home-manager script-module skeleton into a
  # single declarative call. Produces a complete module that:
  #   - defines `custom.scripts.<optionPath>.enable`
  #   - installs a writeShellApplication (auto `set -euo pipefail` + PATH from
  #     runtimeInputs, so bare command names resolve and are guaranteed present)
  #   - optionally asserts Wayland
  #   - optionally contributes a niri keybind (guarded behind niri.enable)
  #
  # Arguments:
  #   name          - binary name (also the option leaf unless optionName given)
  #   optionName    - dotted option path under custom.scripts (default: name)
  #   description   - mkEnableOption description
  #   runtimeInputs - list of packages (function pkgs -> [pkg]) on the PATH
  #   text          - the shell script body
  #   requiresWayland - bool, adds the Wayland assertion (default false)
  #   keybind       - nullable niri keybind line, e.g. ''Mod+Shift+O { spawn "ocr-tool"; }''
  #   extraConfig   - extra home-manager config merged into the module
  #
  # Returns an attrset module { imports = [ <module fn> ]; }, so a script file
  # is simply:  { lib, ... }: lib.custom.mkScript { ... }
  # (the inner module fn is wrapped in imports because a module file may not be
  #  a function returning a function).
  # ---------------------------------------------------------------------------
  mkScript = {
    name,
    optionName ? name,
    description,
    runtimeInputs ? (_pkgs: []),
    text,
    requiresWayland ? false,
    keybind ? null,
    extraOptions ? {},
    extraAssertions ? (_config: []),
    extraConfig ? {},
  }: {
    imports = [
      ({
        config,
        pkgs,
        ...
      }: let
        cfg = lib.getAttrFromPath (lib.splitString "." optionName) config.custom.scripts;
        tool = pkgs.writeShellApplication {
          inherit name text;
          runtimeInputs = runtimeInputs pkgs;
        };
      in {
        options.custom.scripts = lib.setAttrByPath (lib.splitString "." optionName) ({
            enable = lib.mkEnableOption description;
          }
          // extraOptions);

        config = lib.mkIf cfg.enable (lib.mkMerge [
          {
            home.packages = [tool];
          }
          (lib.mkIf requiresWayland {
            assertions = [(mkRequireWayland config name)];
          })
          {
            assertions = extraAssertions config;
          }
          (lib.mkIf (keybind != null) {
            custom.programs.niri.keybinds =
              lib.mkIf config.custom.programs.niri.enable [keybind];
          })
          (
            if lib.isFunction extraConfig
            then extraConfig {inherit config pkgs;}
            else extraConfig
          )
        ]);
      })
    ];
  };

  # ---------------------------------------------------------------------------
  # mkRustdeskConfigScript: shell that writes RustDesk2.toml once (if absent)
  # from a server address and a key, BOTH read from files at runtime. This is
  # the shared writer for the NixOS system daemon and the home-manager program.
  #
  # FIX: previously `server` was interpolated literally while callers passed a
  # sops *path*, so the config ended up with `/run/secrets/...` instead of the
  # address. Now both serverFile and keyFile are read at runtime.
  #
  #   configFile  - target RustDesk2.toml path
  #   serverFile  - file containing the relay/rendezvous address
  #   keyFile     - file containing the server public key
  # ---------------------------------------------------------------------------
  mkRustdeskConfigScript = {
    configFile,
    serverFile,
    keyFile,
  }: ''
    config_file="${configFile}"
    if [ ! -f "$config_file" ]; then
      server=$(tr -d '\n' < ${serverFile})
      key=$(tr -d '\n' < ${keyFile})
      mkdir -p "$(dirname "$config_file")"
      cat > "$config_file" <<EOF
    rendezvous_server = "$server"
    relay_server = "$server"
    api_server = ""
    key = "$key"

    [options]
    custom-rendezvous-server = "$server"
    relay-server = "$server"
    key = "$key"
    EOF
    fi
  '';

  # ---------------------------------------------------------------------------
  # mkTerminalPalette: map a stylix base16 color set to the 16 ANSI slots.
  # Returns an attrset { normal = { black = ...; ... }; bright = { ... }; }
  # consumed by foot/ghostty (each formats it to its own syntax).
  #
  # Standard base16 -> ANSI mapping (Chris Kempson scheme convention).
  # ---------------------------------------------------------------------------
  mkTerminalPalette = colors: {
    normal = {
      black = colors.base00;
      red = colors.base08;
      green = colors.base0B;
      yellow = colors.base0A;
      blue = colors.base0D;
      magenta = colors.base0E;
      cyan = colors.base0C;
      white = colors.base05;
    };
    bright = {
      black = colors.base03;
      red = colors.base08;
      green = colors.base0B;
      yellow = colors.base0A;
      blue = colors.base0D;
      magenta = colors.base0E;
      cyan = colors.base0C;
      white = colors.base07;
    };
  };

  # ---------------------------------------------------------------------------
  # mkContainer: quadlet container with the shared windwaker boilerplate baked
  # in (autoStart, Restart=always/RestartSec=10, RequiresMountsFor for the
  # docker volume root, default network and TZ). Per-service files only supply
  # the genuinely-varying fields.
  #
  # This is for windwaker host-specific services. Host-specific containers stay
  # host-specific; this only deduplicates the repeated unit boilerplate.
  #
  # Arguments mirror virtualisation.quadlet.containers.<name>.containerConfig
  # plus a few conveniences:
  #   dockerVolumeDir  - bind-mount root (default /mnt/docker)
  #   network          - single network name (default "lan_bridge"); use
  #                      `networks` for the full list to override
  #   tz               - TZ env (default "America/Toronto"; set null to omit)
  #   requiresMounts   - add RequiresMountsFor for dockerVolumeDir (default true)
  #   containerConfig  - the rest of the quadlet containerConfig verbatim
  #   serviceConfig    - extra serviceConfig merged over the Restart defaults
  #   unitConfig       - extra unitConfig merged over RequiresMountsFor
  # ---------------------------------------------------------------------------
  mkContainer = {
    dockerVolumeDir ? "/mnt/docker",
    network ? "lan_bridge",
    networks ? null,
    tz ? "America/Toronto",
    requiresMounts ? true,
    containerConfig ? {},
    serviceConfig ? {},
    unitConfig ? {},
    autoStart ? true,
    ...
  } @ args: let
    extraArgs = builtins.removeAttrs args [
      "dockerVolumeDir"
      "network"
      "networks"
      "tz"
      "requiresMounts"
      "containerConfig"
      "serviceConfig"
      "unitConfig"
      "autoStart"
    ];
    # Always carry the caller's environments through; layer TZ on top only when
    # a timezone is requested. (A previous version only kept environments when
    # tz != null, silently dropping PUID/PGID/etc. on tz = null containers.)
    mergedEnvironments =
      lib.optionalAttrs (tz != null) {TZ = tz;}
      // (containerConfig.environments or {});
  in
    {
      inherit autoStart;
      containerConfig =
        {
          networks =
            if networks != null
            then networks
            else [network];
        }
        // lib.optionalAttrs (mergedEnvironments != {}) {
          environments = mergedEnvironments;
        }
        // (builtins.removeAttrs containerConfig ["environments"]);
      serviceConfig =
        {
          Restart = "always";
          RestartSec = "10";
        }
        // serviceConfig;
      unitConfig =
        lib.optionalAttrs requiresMounts {
          RequiresMountsFor = [dockerVolumeDir];
        }
        // unitConfig;
    }
    // extraArgs;
}
