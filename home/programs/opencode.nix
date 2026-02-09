{
  pkgs,
  inputs,
  ...
}: let
  opencodePkg = inputs.opencode.packages.${pkgs.system}.default;

  # TODO: Remove this override once upstream issue #12817 is resolved
  # https://github.com/anomalyco/opencode/issues/12817
  fixedNodeModules = opencodePkg.node_modules.overrideAttrs (old: {
    outputHash = "sha256-fPXBw/ZBo2J8kIjgfVh5cwBfMRQWOpBH7djHncnSdpA=";
  });

  fixedOpencode = opencodePkg.override {
    node_modules = fixedNodeModules;
  };
in {
  home.packages = [
    fixedOpencode
  ];

  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    "theme" = "dark";
    "provider" = {
      "github-copilot" = {};
    };
  };
}
