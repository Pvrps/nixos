{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.chatterino;

  # Chatterino7 fork with full Kick.com + Twitch merged-chat support.
  # Upstream chatterino2 has no Kick support (only the IRC /kick command);
  # this is the only fork that adds a real Kick.com chat integration while
  # keeping all 7TV features (paints, personal emotes, animated avatars).
  #
  # MAINTENANCE: pinned to the head of the `002-polish-kick-integration`
  # branch. Update rev+hash together:
  #   git ls-remote https://github.com/sambegui/chatterino7 002-polish-kick-integration
  #   nix run nixpkgs#nix-prefetch -- --unpack \
  #     https://github.com/sambegui/chatterino7/archive/<rev>.tar.gz
  # Drop this override if Kick support ever lands in upstream chatterino2.
  chatterino7-kick = pkgs.chatterino2.overrideAttrs (old: {
    pname = "chatterino7";
    version = "7.5.4-kick";

    # The fork's CMakeLists find_package()s Qt6::WebSockets (for the Kick
    # WebSocket connection), which upstream chatterino2 does not pull in, so
    # it is absent from nixpkgs' common.nix buildInputs.
    buildInputs = (old.buildInputs or []) ++ [pkgs.kdePackages.qtwebsockets];

    src = pkgs.fetchFromGitHub {
      owner = "sambegui";
      repo = "chatterino7";
      rev = "e0cd24df8b8a79658ec0e124d4591ebe860b462f";
      hash = "sha256-KSvp8ojBQeGmcs6VlgNzXJZ/45MF9ObmgI0bAG8x6J4=";
      fetchSubmodules = true;
      leaveDotGit = true;
      postFetch = ''
        git -C $out rev-parse --short HEAD > $out/GIT_HASH
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };

    meta =
      old.meta
      // {
        description = "Chatterino7 fork with full Kick.com + Twitch.tv chat support";
        longDescription = ''
          A fork of Chatterino7 (itself a 7TV fork of Chatterino2) that adds
          comprehensive Kick.com chat integration: merged Kick + Twitch chat
          views, platform indicator badges, live status indicators, 7TV emotes
          for Kick channels, and Kick OAuth authentication.
        '';
        homepage = "https://github.com/sambegui/chatterino7";
      };
  });

  # The fork reads CHATTERINO_KICK_CLIENT_ID / CHATTERINO_KICK_CLIENT_SECRET
  # env vars as a runtime fallback when no build-time credentials were passed
  # via CMake.  We read them from sops-managed secret files at launch so the
  # credentials never appear in the Nix store, git, or process argv.
  # Follows the same pattern as the opencode module's context7-api-key.
  #
  # symlinkJoin merges the wrapper script into bin/ while keeping the
  # original's share/ (desktop entry + icon) so app launchers find it.
  chatterino7-wrapped = pkgs.symlinkJoin {
    name = "chatterino";
    paths = [
      (pkgs.writeShellScriptBin "chatterino" ''
        ${lib.optionalString (cfg.kickClientIdPath != "") ''
          export CHATTERINO_KICK_CLIENT_ID="$(cat ${cfg.kickClientIdPath} | tr -d '\n')"
        ''}
        ${lib.optionalString (cfg.kickClientSecretPath != "") ''
          export CHATTERINO_KICK_CLIENT_SECRET="$(cat ${cfg.kickClientSecretPath} | tr -d '\n')"
        ''}
        exec ${chatterino7-kick}/bin/chatterino "$@"
      '')
      chatterino7-kick
    ];
  };
in {
  options.custom.programs.chatterino = {
    enable = lib.mkEnableOption "Chatterino2 Twitch chat client";

    kickClientIdPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Path to a file containing the Kick OAuth client ID.
        Read at runtime and exported as CHATTERINO_KICK_CLIENT_ID so the
        credential never enters the Nix store (e.g. a sops secret path).
      '';
    };

    kickClientSecretPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Path to a file containing the Kick OAuth client secret.
        Read at runtime and exported as CHATTERINO_KICK_CLIENT_SECRET so the
        credential never enters the Nix store (e.g. a sops secret path).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [chatterino7-wrapped];
  };
}
