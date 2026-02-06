{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    inputs.opencode.packages.${pkgs.system}.default
  ];

  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    "theme" = "dark";
    "provider" = {
      "github-copilot" = {};
    };
  };
}
