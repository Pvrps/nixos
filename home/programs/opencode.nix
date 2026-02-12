{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    opencode
  ];

  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    "theme" = "dark";
    "provider" = {
      "github-copilot" = {};
    };
  };
}
