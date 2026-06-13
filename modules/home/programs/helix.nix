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
          just-lsp = {command = "${pkgs.just-lsp}/bin/just-lsp";};
          nixd = {command = "${pkgs.nixd}/bin/nixd";};
          basedpyright = {
            command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
            args = ["--stdio"];
          };
          ols = {command = "${pkgs.ols}/bin/ols";};
          jdtls = {
            command = "${pkgs.jdt-language-server}/bin/jdtls";
            args = ["--jvm-arg=-javaagent:${pkgs.lombok}/share/java/lombok.jar"];
          };
        };
        language = [
          {
            name = "nix";
            auto-format = true;
            language-servers = ["nixd"];
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
              args = ["--stdin-filepath" "file.js"];
            };
          }
          {
            name = "typescript";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.ts"];
            };
          }
          {
            name = "jsx";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.jsx"];
            };
          }
          {
            name = "tsx";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.tsx"];
            };
          }
          {
            name = "json";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.json"];
            };
          }
          {
            name = "html";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.html"];
            };
          }
          {
            name = "css";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.css"];
            };
          }
          {
            name = "scss";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.scss"];
            };
          }
          {
            name = "markdown";
            auto-format = true;
            formatter = {
              command = "${pkgs.prettierd}/bin/prettierd";
              args = ["--stdin-filepath" "file.md"];
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
          {
            name = "just";
            auto-format = true;
            language-servers = ["just-lsp"];
          }
          {
            name = "odin";
            auto-format = true;
            language-servers = ["ols"];
            formatter = {command = "${pkgs.ols}/bin/odinfmt";};
          }
          {
            name = "java";
            auto-format = true;
            language-servers = ["jdtls"];
          }
        ];
      };
    };
  };
}
