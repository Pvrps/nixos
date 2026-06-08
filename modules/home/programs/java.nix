{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.java;

  gradleWithToolchains = pkgs.gradle.overrideAttrs (old: {
    fixupPhase =
      old.fixupPhase
      or ""
      + ''
        cat > $out/lib/gradle/gradle.properties <<EOF
        org.gradle.java.installations.paths=${lib.concatStringsSep "," [
          pkgs.zulu8
          pkgs.zulu11
          pkgs.zulu17
          pkgs.zulu21
        ]}
        EOF
      '';
  });

  # Each Zulu JDK gets a symlink under ~/.jdks/ so that Gradle's
  # IntellijInstallationSupplier (and LinuxInstallationSupplier in
  # newer versions) auto-discovers them, just like IntelliJ IDEA
  # downloads do.
  jdkEntries = let
    jdks = [
      {
        name = "zulu-8";
        pkg = pkgs.zulu8;
      }
      {
        name = "zulu-11";
        pkg = pkgs.zulu11;
      }
      {
        name = "zulu-17";
        pkg = pkgs.zulu17;
      }
      {
        name = "zulu-21";
        pkg = pkgs.zulu21;
      }
    ];
  in
    builtins.listToAttrs (map
      (jdk: {
        name = ".jdks/${jdk.name}";
        value.source = jdk.pkg;
      })
      jdks);
in {
  options.custom.programs.java.enable = lib.mkEnableOption "Java development environment";

  config = lib.mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.zulu21;
    };

    home.packages = with pkgs; [
      (writeShellScriptBin "java8" ''
        exec "${zulu8}/bin/java" "$@"
      '')
      (writeShellScriptBin "java11" ''
        exec "${zulu11}/bin/java" "$@"
      '')
      (writeShellScriptBin "java17" ''
        exec "${zulu17}/bin/java" "$@"
      '')
      (writeShellScriptBin "java21" ''
        exec "${zulu21}/bin/java" "$@"
      '')
      gradleWithToolchains
      (writeShellScriptBin "kill-gradle-daemons" ''
        echo "Stopping all Gradle daemons..."
        pkill -f "org.gradle.launcher.daemon.bootstrap.GradleDaemon" 2>/dev/null
        rm -rf "$HOME/.gradle/daemon"
        echo "Done — next Gradle invocation will start fresh."
      '')
    ];

    home.file =
      jdkEntries
      // {
        ".gradle/gradle.properties".text = ''
          # ---- NixOS-managed (custom.programs.java) ----
          org.gradle.java.installations.paths=${pkgs.zulu8},${pkgs.zulu11},${pkgs.zulu17},${pkgs.zulu21}
        '';
      };
  };
}
