{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.custom.programs.termfilepickers;
  terminalCommand = cfg.terminal.command or [];
  terminalExecArgs = cfg.terminal.execArgs or [];
  yaziTerminal = pkgs.writeShellScriptBin "yazi-terminal" ''
    set -eu

    exec ${lib.escapeShellArgs (terminalCommand ++ terminalExecArgs ++ ["${pkgs.yazi}/bin/yazi"])} "$@"
  '';
  xdgOpen = pkgs.writeShellScriptBin "xdg-open" ''
    set -eu

    if [ "$#" -eq 1 ] && [ -d "$1" ]; then
      exec ${yaziTerminal}/bin/yazi-terminal "$1"
    fi

    exec env -u NIXOS_XDG_OPEN_USE_PORTAL DE=generic ${pkgs.xdg-utils}/bin/xdg-open "$@"
  '';
in {
  imports = [
    inputs.xdp-termfilepickers.homeManagerModules.default
  ];

  options.custom.programs.termfilepickers = {
    enable = lib.mkEnableOption "XDG file picker portal using yazi";
    terminal = {
      command = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Terminal command used to host yazi for file picker and directory opening.";
      };
      execArgs = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "Arguments inserted between the terminal command and yazi command.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.yazi.enable;
        message = "custom.programs.termfilepickers.enable requires custom.programs.yazi.enable = true";
      }
      {
        assertion = cfg.terminal.command != null;
        message = "custom.programs.termfilepickers.enable requires custom.programs.termfilepickers.terminal.command to be set by a terminal module or user config.";
      }
      {
        assertion = cfg.terminal.execArgs != null;
        message = "custom.programs.termfilepickers.enable requires custom.programs.termfilepickers.terminal.execArgs to be set by a terminal module or user config.";
      }
    ];

    xdg = {
      portal.enable = true;

      desktopEntries.yazi-terminal = {
        name = "Yazi (terminal)";
        comment = "Open directory in Yazi inside a terminal";
        exec = "${yaziTerminal}/bin/yazi-terminal %f";
        icon = "yazi";
        terminal = false;
        categories = ["System" "FileManager" "FileTools"];
        mimeType = ["inode/directory"];
      };

      mimeApps.defaultApplications = {
        "inode/directory" = "yazi-terminal.desktop";
      };
    };

    services.xdg-desktop-portal-termfilepickers = {
      enable = true;
      package = inputs.xdp-termfilepickers.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        customYazi = pkgs.yazi;
      };
      config.terminal_command = terminalCommand;
    };

    home.packages = [
      xdgOpen
      yaziTerminal
    ];

    programs.yazi.settings.opener.open = lib.mkDefault [
      {
        run = ''xdg-open "$@"'';
        desc = "Open";
        orphan = true;
      }
    ];

    custom.programs.niri.windowRules = lib.mkIf config.custom.programs.niri.enable [
      ''        window-rule {
                    match app-id="file-chooser"
                    open-floating true
                }''
    ];
  };
}
