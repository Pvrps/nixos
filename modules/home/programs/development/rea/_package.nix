# REA (Reverse Engineer Anything): the `rea-agents` npm release, wrapped so
# every analysis engine it supports here is found by absolute path.
#
# The npm tarball is self-contained (bundled node_modules, prebuilt node-pty
# addon, the agent skill under skills/), so it is fetched as-is instead of
# going through buildNpmPackage. The optional frida addon is not bundled and
# stays unavailable (runtime instrumentation is out of scope for now).
#
# Underscore prefix: import-tree skips this file; rea.nix callPackages it.
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  nodejs_24,
  procps,
  util-linux,
  ghidra,
  jdk25,
  apktool,
  binwalk,
  unblob,
  e2fsprogs,
  gdb,
  rizin,
  binutils,
  wireshark-cli,
  mitmproxy,
  android-tools,
  chromium,
}: let
  # MAINTENANCE: npm release pin, see MAINTENANCE.md
  version = "6.9.0";
  integrity = "sha512-KqDn1UR5BMqHoQ3MGAnPuWiSKwgdFaz1L/uUNgrKt+1W8kPtgYP8AWEOXIF1lDIOBVyPuYIIst2iamo1Wf3r8g==";

  # The JADX engine REA drives for Java/APK decompilation. REA pins this exact
  # release in src/android/JadxRelease.ts; hash taken from its docs.
  # MAINTENANCE: follows REA's pinned JADX release, see MAINTENANCE.md
  jadxMcpJar = fetchurl {
    url = "https://github.com/1013503897/jadx-headless-mcp/releases/download/v0.7.1/jadx-headless-mcp-0.7.1-all.jar";
    hash = "sha256-bl6s9QC2QpK/tzxJeXwZWPbuRGRuQ+hoA5rn/rVz/3U=";
  };

  # Tools REA spawns by name; everything else is pinned by absolute path below.
  runtimePath = lib.makeBinPath [
    procps # REA refuses to launch Ghidra/JADX/firmware/JS children without procps `ps`
    jdk25
    e2fsprogs # debugfs, used by unblob for ext filesystems
    unblob
    binwalk
    binutils
    android-tools
  ];
in
  stdenv.mkDerivation {
    pname = "rea";
    inherit version;

    src = fetchurl {
      url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${version}.tgz";
      hash = integrity;
    };
    sourceRoot = "package";

    nativeBuildInputs = [makeWrapper autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      # Prebuilt addons for other platforms (autoPatchelf would choke on them)
      rm -rf node_modules/@lydell/node-pty-{darwin,win32}-* \
        node_modules/@lydell/node-pty-linux-arm64 \
        native/windows

      mkdir -p $out/lib/rea $out/bin $out/share/rea
      cp -r . $out/lib/rea
      ln -s $out/lib/rea/skills $out/share/rea/skills

      # REA_MCP_*: keep the MCP catalog small. Output schemas are 4.3 of its
      # 4.6 MB and only describe return values (REA still validates them
      # server-side); jeb/frida are left out because they can't work here
      # (commercial engine / addon not bundled). Every request carries the
      # catalog, so this is context the agent gets back.
      makeWrapper ${lib.getExe nodejs_24} $out/bin/rea \
        --add-flags $out/lib/rea/scripts/rea.mjs \
        --prefix PATH : ${runtimePath} \
        --set JAVA_HOME ${jdk25.home} \
        --set GHIDRA_INSTALL_DIR ${ghidra}/lib/ghidra \
        --set REA_JADX_MCP_JAR ${jadxMcpJar} \
        --set REA_APKTOOL_COMMAND ${lib.getExe apktool} \
        --set REA_BINWALK_COMMAND ${lib.getExe binwalk} \
        --set REA_UNBLOB_COMMAND ${lib.getExe unblob} \
        --set REA_GDB_COMMAND ${lib.getExe gdb} \
        --set REA_RIZIN_COMMAND ${rizin}/bin/rizin \
        --set REA_OBJDUMP_COMMAND ${binutils}/bin/objdump \
        --set REA_ADB_PATH ${android-tools}/bin/adb \
        --set REA_TSHARK_COMMAND ${wireshark-cli}/bin/tshark \
        --set REA_CAPINFOS_COMMAND ${wireshark-cli}/bin/capinfos \
        --set REA_MITMDUMP_COMMAND ${mitmproxy}/bin/mitmdump \
        --set REA_BROWSER_EXECUTABLE ${lib.getExe chromium} \
        --set REA_TSHARK_PRLIMIT_COMMAND ${util-linux}/bin/prlimit \
        --set REA_FIRMWARE_PRLIMIT_COMMAND ${util-linux}/bin/prlimit \
        --set REA_JAVASCRIPT_PRLIMIT_COMMAND ${util-linux}/bin/prlimit \
        --set REA_EVM_PRLIMIT_COMMAND ${util-linux}/bin/prlimit \
        --set-default REA_MCP_OUTPUT_SCHEMA_PROFILE off \
        --set-default REA_MCP_TOOL_FAMILIES direct,enhanced,native,artifact,managed,firmware,android,pcap,flutter,apktool,adb,browser,electron,javascript-runtime,application,session

      runHook postInstall
    '';

    meta = {
      description = "Reverse engineer anything with agents (MCP server + CLI)";
      homepage = "https://github.com/morluto/rea";
      license = lib.licenses.mit;
      mainProgram = "rea";
      platforms = ["x86_64-linux"];
    };
  }
