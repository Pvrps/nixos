{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.yazi;
in {
  options.custom = {
    programs.yazi = {
      enable = lib.mkEnableOption "Yazi terminal file manager";
      sftp = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.str;
              description = "SFTP Host";
            };
            user = lib.mkOption {
              type = lib.types.str;
              description = "SFTP User";
            };
            port = lib.mkOption {
              type = lib.types.int;
              default = 22;
              description = "SFTP Port";
            };
            passwordSecret = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Path to file containing the password";
            };
          };
        });
        default = {};
        description = "SFTP server configurations for Yazi VFS";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };

    home.activation.setupYaziVfs = lib.mkIf (cfg.sftp != {}) (lib.hm.dag.entryAfter ["writeBoundary"] ''
      YAZI_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
      mkdir -p "$YAZI_CONFIG_DIR"
      VFS_TOML="$YAZI_CONFIG_DIR/vfs.toml"

      # Securely create the file without leaking to Nix Store
      touch "$VFS_TOML"
      chmod 600 "$VFS_TOML"
      > "$VFS_TOML"

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: srv: ''
          echo "[services.${name}]" >> "$VFS_TOML"
          echo "type = \"sftp\"" >> "$VFS_TOML"
          echo "host = \"${srv.host}\"" >> "$VFS_TOML"
          echo "user = \"${srv.user}\"" >> "$VFS_TOML"
          echo "port = ${toString srv.port}" >> "$VFS_TOML"
          ${lib.optionalString (srv.passwordSecret != null) ''
            # Read the password file at activation time directly into the TOML
            echo "password = \"$(cat ${srv.passwordSecret})\"" >> "$VFS_TOML"
          ''}
          echo "" >> "$VFS_TOML"
        '')
        cfg.sftp)}
    '');
  };
}
