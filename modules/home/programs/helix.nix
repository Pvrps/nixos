{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.helix;
in {
  options.custom.programs.helix.enable = lib.mkEnableOption "Helix editor";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.lsp.enable;
        message = "custom.programs.helix.enable requires custom.programs.lsp.enable = true";
      }
    ];

    programs.helix = {
      enable = true;
      defaultEditor = true;

      settings = {
        editor = {
          line-number = "relative";
          cursor-shape.insert = "bar";
          indent-guides.render = true;
          lsp.display-messages = true;
          color-modes = true;

          statusline = {
            left = ["mode" "spinner"];
            center = ["file-name"];
            right = ["diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type"];
            separator = "│";
          };
        };
      };

      languages = {
        language-server = {
          nil = {command = "${pkgs.nil}/bin/nil";};
          basedpyright = {
            command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
            args = ["--stdio"];
            config = {
              basedpyright.analysis = {
                typeCheckingMode = "standard";
                diagnosticMode = "workspace";
              };
            };
          };
        };

        language = [
          {
            name = "nix";
            auto-format = true;
            formatter = {command = "${pkgs.alejandra}/bin/alejandra";};
          }
          {
            name = "python";
            auto-format = true;
            language-servers = ["basedpyright" "ruff"];
            formatter = {
              command = "${pkgs.ruff}/bin/ruff";
              args = ["format" "-"];
            };
          }
          {
            name = "bash";
            auto-format = true;
            formatter = {
              command = "${pkgs.shfmt}/bin/shfmt";
              args = ["-i" "2" "-ci"];
            };
          }
          {
            name = "javascript";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "typescript";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "jsx";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "tsx";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "json";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "html";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "css";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "scss";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "markdown";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["$FILENAME"];
            };
          }
          {
            name = "toml";
            auto-format = true;
            formatter = {
              command = "${pkgs.taplo}/bin/taplo";
              args = ["fmt" "-"];
            };
          }
          {
            name = "fish";
            auto-format = true;
            formatter = {command = "${pkgs.fish}/bin/fish_indent";};
          }
        ];
      };
    };
  };
}
