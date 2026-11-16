# REA: reverse engineering in an isolated VM

[REA](https://github.com/morluto/rea) ("Reverse Engineer Anything") gives an AI
agent reverse-engineering tools: Ghidra decompilation, JADX/Apktool for
Java and Android, Binwalk/Unblob for firmware, GDB/Rizin for debugging,
mitmproxy/tshark for traffic, and more. Here it runs with OpenCode and Claude
Code inside **rea-vm**, a microVM on navi, so whatever you analyse never runs on
(or talks to) the desktop.

## Quick start

```sh
rea ~/Downloads/firmware.bin     # new case for it, agent starts working on it
rea some.apk -m "how does the login flow work?"
rea 2026-11-13-firmware.bin      # reopen a case, continuing its last session
rea                              # agent in ~/rea, no particular case
rea shell                        # plain shell in the VM
rea status | stop | restart | reset
```

Whenever the VM runs, the **live report** is at <http://localhost:8471>. It
opens in your browser when the VM starts or a new case is created and
updates by itself as the agent works: an index of all cases with search
across every note and finding, and a page per case (summary, highlights,
targets with hashes, components, functions, network endpoints, behaviours,
secrets, open questions, next steps, the full notes, artifact downloads).

`~/rea` is the only folder shared with the VM, at the same path on both sides.
It's a normal persisted folder (like `~/Development`) with no size limit, so
clean up big extractions in old cases yourself.

### First run

1. `rea shell`, then run `claude` (from `~`, not inside `~/rea`) and log in
   with your Claude account (it prints a URL; open it on the desktop and
   paste the code back). The login is stored on the VM's own disk, never
   copied from the desktop.
2. `exit`, then `rea <something>`. If OpenCode says the Claude provider isn't
   connected, run `opencode2 auth` in `rea shell` and connect it.
3. Expect a handful of OpenSnitch prompts during the first session (see below).

## Cases

`rea <path>` copies the target into a new case folder (the original stays
untouched) and starts the agent on it:

```
~/rea/2026-11-13-firmware.bin/
  target/         read-only copy of the target
  case.json       target list with sha256, size and type
  findings.json   structured findings - what the report shows
  notes.md        the agent's running log (facts vs hypotheses, evidence)
  artifacts/      extracted firmware, decompiled sources, captures, ...
  scripts/        helper / repro scripts
```

`rea <case>` (the folder name, or its `~/rea/<case>` path) resumes where you
left off. Sessions run from `~/work/sessions/<case>` on the VM's own disk,
not from the case folder: OpenCode loads any `AGENTS.md` it finds between a
file it reads and the session folder, and a target must never be in that
path. Targets you get inside the VM (e.g. an APK pulled from the TV) become
cases too - the agent runs `rea-case new <path>`; just ask.

## Agents

Everything is driven by the AI; there are no commands to learn. Every session
starts with **re-lead**, which loads the `rea-case` skill (workflow, findings
schema, playbooks for ELF, Java, APK/Android TV and firmware) and REA's own
skill, keeps `findings.json` / `notes.md` current, and delegates:

| Agent         | Model            | Does                                              |
| ------------- | ---------------- | ------------------------------------------------- |
| `re-lead`     | Opus 5.5, high   | runs the case, decides, writes findings and notes |
| `re-analyst`  | Sonnet 5.5, high | deep dives on one function/class/protocol/binary  |
| `re-scout`    | Haiku 5.5        | bulk work: inventories, string sweeps, summaries  |
| `re-verifier` | Sonnet 5.5, high | read-only check of claims before a case is `done` |

By convention subagents write only to `artifacts/`, `scripts/` and `~/work`
(their edit tool is limited to those; re-verifier has no shell and no edits).
These are guard rails for the agents' own work, not a security boundary -
everything in the VM runs as the same user. Models are options in
`modules/home/programs/development/rea.nix`
(`custom.programs.rea.models.{lead,analyst,scout}`); Opus also works on the
Pro plan, it just uses the usage limit faster. Instructions live in the VM's
global `AGENTS.md` (from the same module); project-level `AGENTS.md` /
`.opencode` files are ignored (`OPENCODE_DISABLE_PROJECT_CONFIG`) and case
folders are kept outside the session folder, so instruction files inside a
target aren't loaded as rules.

## Network prompts (OpenSnitch)

Every **new** outbound destination from the VM pops up an OpenSnitch dialog on
the desktop showing the program, its command line and the destination:
_Allow once_, _Allow always_ or _Deny_. No answer means deny, and when the
prompt app isn't running everything not already allowed is denied. `rea`
starts the app (`rea-opensnitch-ui` user service) automatically.

Pre-allowed without asking: localhost, DNS to 1.1.1.1/9.9.9.9, and Anthropic
(`*.anthropic.com`, `*.claude.ai`, `*.claude.com`) for the agent itself.
"Allow always" answers are kept on the VM's disk.

Enforced on navi regardless of what you click or what runs in the VM (even
as root there; iptables `raw`/`mangle` tables, ahead of tailscale's and
NixOS's own rules, and kept in place if the firewall reload fails):

| Destination from the VM                                                                         | Result                           |
| ----------------------------------------------------------------------------------------------- | -------------------------------- |
| navi itself                                                                                     | blocked (except the prompt port) |
| router on the IoT network (`10.0.20.1`)                                                         | blocked                          |
| PCs (`10.0.0.x`), servers (`10.0.10.x`), other private ranges, tailscale, link-local, multicast | blocked                          |
| anything not leaving via `eno1`, IPv6                                                           | blocked                          |
| IoT network `10.0.20.0/24` (TV, ...)                                                            | prompt                           |
| internet                                                                                        | prompt (Anthropic pre-allowed)   |

Nothing can connect _into_ the VM from the LAN. The allowed and blocked
addresses are `custom.reaVm.lanAllowed` / `lanBlocked` in
`modules/hosts/navi/default.nix`.

## Android TV

On the TV: enable Developer options, then **Network debugging** (sometimes
"ADB debugging"). Then ask the agent, or do it yourself in `rea shell`:

```sh
adb connect <tv-ip>:5555     # OpenSnitch prompt -> Allow always; accept on the TV
adb shell pm list packages
adb shell pm path com.example.app
adb pull /data/app/.../base.apk ~/rea/
```

The adb key lives in the VM (`~/.android`), so the TV stays paired.

**Watching an app's traffic:** just ask ("capture what the X app sends").
The agent runs mitmproxy in the VM and tunnels the TV's proxy back over the
adb connection the VM already opened, so nothing on navi or the LAN listens:

```sh
mitmdump -p 8080 -w ~/rea/<case>/artifacts/tv.flows &
adb reverse tcp:8080 tcp:8080
adb shell settings put global http_proxy 127.0.0.1:8080
# ... use the app on the TV ...
adb shell settings put global http_proxy :0
adb reverse --remove-all
```

mitmproxy's own upstream connections prompt too; allow `mitmdump` always if
you'll do this often. Most TV apps ignore user-installed CAs (Android 7+), so
some HTTPS stays opaque unless the APK is patched; plain metadata (hosts, SNI,
timing) is still visible.

## What runs where

- **navi** (`modules/nixos/rea-vm`): microvm host, tap `vm-rea`
  (10.88.0.1) with NAT out of `eno1`, the firewall rules above, OpenSnitch UI,
  polkit rule so you can start/stop the VM without sudo, the `rea` launcher,
  and the live report (`rea-report` user service, `modules/nixos/rea-vm/report`).
- **rea-vm** (`modules/hosts/rea-vm`, `nixosConfigurations.rea-vm`):
  10.88.0.2, 8 vCPU, 8 GiB RAM (balloon; unused memory goes back to navi),
  its own store image (it can't see navi's /nix/store), tmpfs root, and one
  persistent disk at `/persist/microvms/rea/persist.img` holding the Claude
  login, OpenCode sessions, Ghidra projects, adb keys, mitmproxy CA and
  OpenSnitch answers. `purps` there has no password, no sudo, no secrets.
- **Login:** the launcher uses its own key (`/persist/microvms/rea/ssh/`)
  over AF_VSOCK; the VM's sshd isn't reachable over any network.
- **Agents:** OpenCode (+ Claude Code for the login) with the `rea` and
  `nixos` MCP servers, the re-\* agents and skills
  (`modules/home/programs/development/{rea,opencode,claude-code}.nix`, skill
  in `modules/home/programs/development/rea/skills/rea-case`, user config
  `modules/users/purps/rea-vm.nix`).

## Security model

A target can contain text that tricks the agent ("prompt injection"), and the
agent has a shell. The VM limits what that can reach:

- **Desktop, secrets, other machines:** unreachable (firewall + VM boundary).
- **`~/rea`:** the VM can read and write it. virtiofsd maps every file it
  creates to purps:users and can't create device nodes, but treat anything
  in `~/rea` as untrusted: don't run it on navi, and open it with tools that
  don't execute content.
- **Claude login:** the one valuable thing inside. Prompts cover most
  destinations, but not all of them: DNS to 1.1.1.1/9.9.9.9 and anything to
  Anthropic are pre-allowed for every process, so a hijacked agent could leak
  it through DNS queries or an upload to someone else's Anthropic account
  without a prompt. If you suspect a leak (or after analysing something
  nasty), revoke the session in your Claude account settings and `rea reset`.
- **Prompt UI:** only the VM's OpenSnitch daemon may reach the UI port on
  navi (an unprivileged process in the VM can't forge prompts; VM root
  could).
- **Disk:** `~/rea` has no size limit, so a runaway extraction in the VM
  could fill `/persist` (you'd notice; delete the case). The VM's own disk is
  a sparse 64 GiB image.
- **The report:** rendered on navi by trusted code from the agent's markdown
  and JSON - raw HTML is escaped, only in-page links are clickable (other
  URLs are shown as text), images and external resources never load (strict
  CSP), symlinks are never followed, artifacts are offered only as downloads,
  and it listens on 127.0.0.1 only (without a login: any local process on
  navi can read it - same as `~/rea` itself).
- **Case creation:** `rea <path>` builds the case outside the share and moves
  it in atomically, and never runs parsers like `file` on the target on navi.
- Starting/stopping/resetting the VM is allowed for purps only via polkit
  (`microvm@rea`, `rea-vm-reset`).

## Maintenance

- **Updates:** `just update` bumps REA with the other pinned tools; after
  `just switch` the new VM build is used on the next start (`rea restart` if
  it's running; `rea` tells you when it's out of date). A rebuild never
  restarts a running VM.
- **Check engines:** `rea shell`, then `rea doctor --provider ghidra` (or
  `jadx`, `apktool`, ...). Note: inside the VM, `rea` is REA's own CLI; on
  navi it's the launcher.
- **Reset the VM** (wipes login, sessions, answers; keeps `~/rea`):
  `rea reset`. A blank disk is created on the next start, and the launcher
  forgets the old host key.
- **Logs:** `journalctl -u microvm@rea` (VM console), `rea shell` then
  `journalctl -b` inside.

## Not included (yet)

- USB passthrough (adb over the network covers the TV).
- Frida / live instrumentation: the npm addon isn't bundled and needs a
  rooted device for Android apps.
- WABT, sigrok and pwntools workflows: REA requires exact versions nixpkgs
  doesn't have.
- Commercial engines (Hopper, IDA, JEB).
