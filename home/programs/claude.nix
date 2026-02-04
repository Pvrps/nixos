{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.claude-code.packages.${pkgs.system}.default
  ];

  home.sessionVariables = {
    ANTHROPIC_BASE_URL = "http://127.0.0.1:4141";
    ANTHROPIC_API_KEY = "copilot-api";
    ANTHROPIC_MODEL = "gpt-5-mini";

    CLAUDE_NO_TELEMETRY = "1";
    CLAUDE_AUTO_UPDATE = "0";
  };
}
