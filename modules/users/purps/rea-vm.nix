# purps inside the rea-vm guest (modules/hosts/rea-vm). Deliberately minimal:
# no secrets, no git/ssh identities — only the agents and REA. See REA.md.
{pkgs, ...}: {
  home = {
    username = "purps";
    homeDirectory = "/home/purps";
    stateVersion = "26.05";

    # REA's own wrapper carries the analysis engines; these are for working
    # by hand in `rea shell` (adb to the TV, mitmproxy, quick looks).
    packages = with pkgs; [
      ripgrep
      fd
      jq
      file
      xxd
      android-tools
      mitmproxy
      gdb
      binutils
    ];
  };

  custom.programs = {
    # nixos MCP: the VM is NixOS, so the agent can look up packages/options
    # when it needs a tool that isn't installed.
    opencode = {
      enable = true;
      mcp-nixos.enable = true;
    };
    # Claude Code is here only for the subscription login that OpenCode's
    # Claude provider uses. It runs underneath every OpenCode request, so it
    # gets no MCP servers: anything listed for it is loaded a second time.
    claude-code.enable = true;
    rea.enable = true;
  };

  # Guest root is tmpfs; keep logins, sessions and analysis state on the
  # VM's own volume. (claude-code persists ~/.claude and ~/.claude.json.)
  home.persistence."/persist".directories = [
    ".local/share/opencode"
    ".local/state/opencode"
    ".rea"
    ".cache/rea"
    ".ghidra"
    ".android" # adb keys, so the TV stays paired
    ".mitmproxy" # mitmproxy CA, so the TV keeps trusting it
    "work" # scratch space outside the shared folder
  ];
}
