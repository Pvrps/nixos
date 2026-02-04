{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.claude-code.packages.${pkgs.system}.default
  ];
}
