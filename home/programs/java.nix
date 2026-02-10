{pkgs, ...}: {
  programs.java = {
    enable = true;
    package = pkgs.zulu21;
  };

  home.packages = with pkgs; [
    # Java 8 alias
    (writeShellScriptBin "java8" ''
      exec "${zulu8}/bin/java" "$@"
    '')
    # Java 17 alias
    (writeShellScriptBin "java17" ''
      exec "${zulu17}/bin/java" "$@"
    '')
    # Java 21 alias (explicit)
    (writeShellScriptBin "java21" ''
      exec "${zulu21}/bin/java" "$@"
    '')
  ];
}
