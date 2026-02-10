{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    inputs.prismlauncher.packages.${pkgs.stdenv.hostPlatform.system}.prismlauncher
  ];
}
