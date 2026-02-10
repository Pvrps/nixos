{pkgs, ...}: {
  home.packages = with pkgs; [
    # --- Language Servers (LSP) ---
    nil # nix
    basedpyright # python
    rust-analyzer # rust
    clang-tools # c, cpp
    omnisharp-roslyn # c-sharp, msbuild
    cmake-language-server # cmake
    typescript-language-server # javascript, typescript, jsx, tsx
    vscode-langservers-extracted # html, css, scss, json, jsonc, json5
    jsonnet-language-server # jsonnet
    svelte-language-server # svelte
    bash-language-server # bash
    marksman # markdown
    taplo # toml
    yaml-language-server # yaml
    lemminx # xml
    kotlin-language-server # kotlin
    jdt-language-server # java
    phpactor # php
    solargraph # ruby
    texlab # latex
    nginx-language-server # nginx
    svls # verilog
    ghdl # vhdl
    graphql-language-service-cli # graphql
    dockerfile-language-server # dockerfile
    docker-compose-language-service # docker-compose
    sqls # sql
    jq-lsp # jq

    # --- Formatters & Runtimes ---
    alejandra # nix
    ruff # python
    shfmt # bash
    rustfmt # rust
    prettierd # js, ts, html, css, scss, json, markdown
    nodePackages.sql-formatter # sql
    php # php-only
    python3
    dotnet-sdk # c-sharp / msbuild
    gawk # awk
    nushell # nu
    powershell # powershell
    mermaid-cli # mermaid
    just # just
    csvlens # csv
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
        rust-analyzer = {command = "${pkgs.rust-analyzer}/bin/rust-analyzer";};
        basedpyright = {
          command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
          args = ["--stdio"];
        };
      };

      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {command = "${pkgs.alejandra}/bin/alejandra";};
        }
        {
          name = "rust";
          auto-format = true;
        }
        {
          name = "python";
          auto-format = true;
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
}
