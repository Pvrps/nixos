{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.lsp;
in {
  options.custom.programs.lsp = {
    enable = lib.mkEnableOption "LSP servers and formatters for use with any editor";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # --- Language Servers (LSP) ---
      nil # nix
      basedpyright # python
      typescript-language-server # javascript, typescript, jsx, tsx
      vscode-langservers-extracted # html, css, scss, json, jsonc, json5
      jsonnet-language-server # jsonnet
      svelte-language-server # svelte
      bash-language-server # bash
      marksman # markdown
      taplo # toml
      yaml-language-server # yaml
      lemminx # xml
      jdt-language-server # java
      texlab # latex
      nginx-language-server # nginx
      graphql-language-service-cli # graphql
      dockerfile-language-server # dockerfile
      docker-compose-language-service # docker-compose
      sqls # sql
      jq-lsp # jq

      vtsls # typescript (zed-preferred ts server)
      tailwindcss-language-server # tailwindcss

      # --- Formatters & Runtimes ---
      alejandra # nix
      ruff # python
      shfmt # bash
      rustfmt # rust
      prettierd # js, ts, html, css, scss, json, markdown
      sql-formatter # sql
      python3
      gawk # awk
      mermaid-cli # mermaid
      just # just
      csvlens # csv
    ];
  };
}
