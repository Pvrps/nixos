---
name: rea-case
description: Run a reverse-engineering case end to end in rea-vm - case folder layout, findings.json schema, notes format, per-target playbooks (Linux ELF, Java JAR, Android APK / Android TV, firmware) and how to split work across re-analyst, re-scout and re-verifier. Load at the start of every reverse-engineering task.
---

# Running a REA case

The user watches a live report rendered from your `findings.json` and
`notes.md`, so keep both current: update them after every meaningful step,
not only at the end.

## Case folder

```
~/rea/<YYYY-MM-DD>-<name>/
  target/         read-only copy of what is analysed - never modify
  case.json       created by `rea-case`; target list with sha256/size/type
  findings.json   structured findings (schema below) - re-lead only
  notes.md        chronological log - re-lead only
  artifacts/      everything derived: extracted firmware, decompiled
                  sources, unpacked APKs, captures, dumps
  scripts/        helper / repro scripts you write
```

- Sessions run from `~/work/sessions/<case>` (outside the case, so files in
  a target can't inject instructions); the opening prompt names the case
  folder. Always use absolute `~/rea/<case>/...` paths.
- If the user asks about a target that has no case yet (e.g. something
  pulled with adb into `~/work`), run
  `rea-case new --name <short-slug> --title "<what it is - what you're investigating>" <path>`
  and continue with the printed folder. Name the case after the subject,
  never after a folder: `--name tcl-tv-telemetry --title "TCL TV - vendor
telemetry & analytics"`, not `apks`.
- If `case.json` has an empty `targets` list, run `rea-case inventory ~/rea/<case>`.
- Run targets (dynamic analysis) from a copy under `~/work/runs/<case>/`,
  never from `target/`, always with a timeout.

## findings.json (schema 1)

Write valid JSON (check with `jq . findings.json`). Keep every key; use
empty lists rather than removing them. Every entry should carry
`evidence` (address, offset, file:line, REA evidence ID, capture frame...)
and `confidence` (`high` | `medium` | `low`).

```json
{
  "schema": 1,
  "title": "Short human name of the target",
  "status": "new | triage | mapping | deep-dive | verifying | done",
  "summary": "2-6 sentences, markdown allowed: what it is, what it does, the answer to the user's question",
  "highlights": ["one-line headline findings, most important first"],
  "components": [
    {
      "name": "",
      "kind": "binary|library|service|partition|apk|class|module",
      "path": "",
      "description": "",
      "evidence": ""
    }
  ],
  "functions": [
    {
      "name": "",
      "address": "0x...",
      "file": "",
      "purpose": "",
      "evidence": "",
      "confidence": "high"
    }
  ],
  "network": [
    {
      "endpoint": "host:port or URL",
      "protocol": "",
      "direction": "out|in",
      "purpose": "",
      "evidence": "",
      "confidence": "medium"
    }
  ],
  "secrets": [
    {
      "kind": "key|token|password|cert|url",
      "location": "",
      "value": "redact all but a short prefix",
      "evidence": ""
    }
  ],
  "behaviors": [{ "behavior": "", "evidence": "", "confidence": "low" }],
  "open_questions": ["what is still unknown, phrased as questions"],
  "next_steps": ["concrete next actions"]
}
```

Status moves forward as the work does; set `done` only after re-verifier has
checked the highlights.

**Update it early and often - the user watches it live.** Within the first
few minutes: a proper `title`, `status: "triage"`, and a one-line
`summary` of what you're looking at. Then after every phase and whenever a
subagent reports back: move `status` on, add what you learned (even with
`low` confidence), refresh `summary`, `highlights`, `open_questions` and
`next_steps`. Don't wait for subagents to finish before the first write.

## notes.md

Append-only log under dated headings:

```markdown
## 14:32 - triage

- **Fact:** ELF 64-bit ARM aarch64, stripped, dynamically linked (case.json).
- **Fact:** `curl_easy_perform` imported; called from `FUN_00412a10` (Ghidra).
- **Hypothesis (medium):** uploads telemetry to `api.vendor.com` - see network.
- Next: re-analyst on `FUN_00412a10`.
```

Facts and hypotheses are always labelled. Quote evidence precisely; do not
paste huge listings - put those in `artifacts/` and link the path.

## Workflow

1. **Triage** (re-scout can do most of it): `rea-case inventory`, file types,
   hashes, strings, imports/exports, packers, embedded archives; REA's
   desktop/package inventory tools; write `components` and first highlights.
2. **Map**: entry points, main modules, call graph around interesting APIs
   (network, crypto, IPC, update, auth); pick targets for deep dives.
3. **Deep dive**: one subagent per independent function/component; they
   return findings with evidence; you merge them into findings/notes.
4. **Verify**: re-verifier checks the highlights and any `high` confidence
   claims against the evidence; downgrade or fix what fails.
5. **Wrap up**: summary answers the user's question; open questions and next
   steps are honest; status `done`.

## Delegation

- **re-scout** (fast, cheap): inventories, strings/grep sweeps, listing
  extracted filesystems, summarising very large decompiler output, first
  look at many small files. Give it exact paths and what to return.
- **re-analyst**: deep dive into one function, class, protocol or binary.
  Give it the case path, the target (address/class/file), the question, and
  ask for findings in the findings.json entry shape with evidence.
- **re-verifier**: read-only check of specific claims; give it the claims
  and the evidence they cite.
- Run independent subagents in parallel. Subagents write only to
  `artifacts/`, `scripts/` and `~/work`; you merge their results.

## Playbooks

### Linux ELF

- `file`, `readelf -h -d -n`, hardening (REA binary hardening/ELF notes),
  Go/Rust build info (REA inspectors) - often names the project and deps.
- Ghidra via REA: functions, imports, strings, xrefs; start from interesting
  imports (socket/connect, SSL__, curl__, open/exec, crypto) and `main`.
- Dynamic: copy to `~/work/runs/<case>/`, run under REA process capture or
  `gdb`/rizin with breakpoints on the interesting calls; record what you saw.

### Java JAR / class files

- Unzip to `artifacts/jar/`, read `META-INF/MANIFEST.MF` (Main-Class,
  Class-Path); decompile with JADX through REA (or Ghidra for single
  classes); map packages; look for reflection, native libs (JNI `.so` ->
  ELF playbook), network, crypto, obfuscation (ProGuard names).
- Dynamic: run with the VM's JDK from `~/work/runs/<case>`, optionally with `-verbose:class`
  or a debugger.

### Android APK / Android TV

- Pull from the TV with adb (`adb shell pm path <pkg>`, `adb pull`) into
  `~/work`, then `rea-case new`.
- REA: APK signature, manifest (permissions, exported components, intent
  filters), Apktool resources, JADX classes; Flutter/Unity specifics via REA
  inspectors (`libapp.so`, `global-metadata.dat`).
- Traffic: tunnel the TV's proxy back over adb (nothing listens on the
  network), and always undo it afterwards:

  ```sh
  mitmdump -p 8080 -w ~/rea/<case>/artifacts/tv.flows &   # in the VM
  adb reverse tcp:8080 tcp:8080
  adb shell settings put global http_proxy 127.0.0.1:8080
  # ... reproduce the behaviour on the TV ...
  adb shell settings put global http_proxy :0
  adb reverse --remove-all
  ```

  Many apps pin or ignore user CAs (Android 7+) - report hosts/SNI/timing
  and say what stayed opaque instead of guessing.

### Firmware images

- REA firmware inspection (Binwalk) first, then explicit Unblob extraction
  into `artifacts/extract/`.
- Inventory the extracted filesystem (re-scout): init scripts, services,
  web server, config files, certificates/keys, update mechanism, busybox
  version, custom binaries.
- Custom binaries -> ELF playbook (note the architecture; Ghidra handles
  ARM/MIPS). Bootloader/raw blobs: rizin with explicit arch/base address.

## Network

Every new destination from this VM triggers an allow/deny prompt on the
user's desktop. Before connecting somewhere new (package mirrors, vendor
servers, the TV), say in one line where and why. Never send target data or
findings to third-party services.
