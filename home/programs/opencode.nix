{
  pkgs,
  inputs,
  ...
}: let
  opencodePkg = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = [
    opencodePkg
  ];

  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    "theme" = "dark";
    "provider" = {
      "github-copilot" = {};
    };
  };
}
