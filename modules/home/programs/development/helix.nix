{
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
    };
  };
}
