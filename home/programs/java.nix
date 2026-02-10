{pkgs, ...}: {
  programs.java = {
    enable = true;
    package = pkgs.jdk21;
  };

  home.packages = with pkgs; [
    # Java 8 alias
    (writeShellScriptBin "java8" ''
      exec "${jdk8}/bin/java" "$@"
    '')
    # Java 17 alias
    (writeShellScriptBin "java17" ''
      exec "${jdk17}/bin/java" "$@"
    '')
    # Java 21 alias (explicit)
    (writeShellScriptBin "java21" ''
      exec "${jdk21}/bin/java" "$@"
    '')
  ];
}
