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
  #   pkgs          - nixpkgs instance (from the calling module's args)
  #   name          - binary name (also the option leaf unless optionName given)
  #   optionName    - dotted option path under custom.scripts (default: name)
  #   description   - mkEnableOption description
  #   runtimeInputs - list of packages available on the script's PATH
  #   text          - the shell script body
  #   requiresWayland - bool, adds the Wayland assertion (default false)
  #   keybind       - nullable niri keybind line, e.g. ''Mod+Shift+O { spawn "ocr-tool"; }''
  #   extraConfig   - extra home-manager config merged into the module
  #
  # Returns a module function { config, ... }: { ... }.
  # ---------------------------------------------------------------------------
  mkScript = {
    pkgs,
    name,
    optionName ? name,
    description,
    runtimeInputs ? [],
    text,
    requiresWayland ? false,
    keybind ? null,
    extraConfig ? {},
  }: {config, ...}: let
    cfg = lib.getAttrFromPath (lib.splitString "." optionName) config.custom.scripts;
    tool = pkgs.writeShellApplication {
      inherit name runtimeInputs text;
    };
  in {
    options.custom.scripts = lib.setAttrByPath (lib.splitString "." optionName) {
      enable = lib.mkEnableOption description;
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        home.packages = [tool];
      }
      (lib.mkIf requiresWayland {
        assertions = [(mkRequireWayland config name)];
      })
      (lib.mkIf (keybind != null) {
        custom.programs.niri.keybinds =
          lib.mkIf config.custom.programs.niri.enable [keybind];
      })
      extraConfig
    ]);
  };

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
        // lib.optionalAttrs (tz != null) {
          environments = {TZ = tz;} // (containerConfig.environments or {});
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
