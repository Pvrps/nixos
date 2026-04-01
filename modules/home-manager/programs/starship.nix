{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.starship;
in {
  options.custom.programs.starship.enable = lib.mkEnableOption "Starship cross-shell prompt";

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;

      enableFishIntegration = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings = {
        "$schema" = "https://starship.rs/config-schema.json";

        format = pkgs.lib.concatStrings [
          "$hostname"
          "$os"
          "$shell"
          "$username"
          "$git_branch"
          "$directory"
          "$line_break"
          "$character"
        ];

        hostname = {
          ssh_only = false;
          format = "[$hostname]($style) ";
          style = "fg:240";
        };

        character = {
          success_symbol = "[❯](bold green)";
          error_symbol = "[❯](bold red)";
        };

        git_branch = {
          disabled = false;
          format = "[$symbol$branch(:$remote_branch)]($style) ";
          style = "white";
          symbol = "";
        };

        os = {
          disabled = false;
          format = "$symbol ";
          symbols = {
            Unknown = "[unknown](dimmed black)";
            Debian = "[debian](fg:#A80030)";
            Ubuntu = "[ubuntu](fg:#E95420)";
            Windows = "[windows](fg:#00A4EF)";
            NixOS = "[nix](fg:#8AE9ff)";
            Kali = "[kali](fg:#25867B)";
          };
        };

        shell = {
          disabled = false;
          format = "[$indicator]($style) ";
          style = "dimmed black";
          unknown_indicator = "[unknown](dimmed black)";
          bash_indicator = "[bsh](fg:#F9F1A5)";
          pwsh_indicator = "[psh](fg:#F9F1A5)";
          nu_indicator = "[nu](fg:#F9F1A5)";
          fish_indicator = "[fsh](fg:#F9F1A5)";
        };

        username = {
          disabled = false;
          format = "[$user]($style) ";
          style_user = "fg:#A385FF";
          show_always = true;
        };

        directory = {
          disabled = false;
          format = "[$path]($style)[$read_only]($read_only_style) ";
          style = "dimmed white";
          truncation_length = 1;
          fish_style_pwd_dir_length = 1;
        };
      };
    };
  };
}
