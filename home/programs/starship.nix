{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      format = pkgs.lib.concatStrings [
        "$os"
        "$shell"
        "$username"
        "$git_branch"
        "$directory"
        "$line_break"
        "$character"
      ];

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
          Unknown = "[unknown](bold dimmed black)";
          Debian = "[debian](bold fg:#A80030)";
          Ubuntu = "[ubuntu](bold fg:#E95420)";
          Windows = "[windows](bold fg:#00A4EF)";
          NixOS = "[nix](bold fg:#8AE9ff)";
          Kali = "[kali](bold fg:#25867B)";
        };
      };

      shell = {
        disabled = false;
        format = "[$indicator]($style) ";
        style = "bold dimmed black";
        unknown_indicator = "[unknown](bold dimmed black)";
        bash_indicator = "[bsh](bold fg:#F9F1A5)";
        pwsh_indicator = "[psh](bold fg:#F9F1A5)";
        nu_indicator = "[nu](bold fg:#F9F1A5)";
        fish_indicator = "[fsh](bold fg:#F9F1A5)";
      };

      username = {
        disabled = false;
        format = "[$user]($style) ";
        style_user = "fg:#A385FF";
        show_always = true;
        aliases = { "Purps" = "purps"; };
      };

      directory = {
        disabled = false;
        format = "[$path]($style)[$read_only]($read_only_style) ";
        style = "bold dimmed white";
        truncation_length = 1;
        fish_style_pwd_dir_length = 1;
      };
    };
  };
}
