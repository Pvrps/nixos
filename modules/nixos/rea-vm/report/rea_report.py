"""rea-report: live, read-only HTML report of the REA cases in ~/rea.

Runs on the host. Everything it reads was written inside rea-vm (by an agent
that may have been prompt-injected), so all content is treated as hostile:
markdown is rendered with raw HTML disabled, every value is escaped, files
are opened without following symlinks, artifacts are only offered as
downloads, and a strict Content-Security-Policy forbids any script or
resource that isn't served by this program itself.
"""

import argparse
import hashlib
import html
import json
import os
import re
import stat
import sys
import time
import urllib.parse
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from markdown_it import MarkdownIt

MAX_TEXT = 4 * 1024 * 1024
MAX_NOTES = 512 * 1024
MAX_ROWS = 500
MAX_DEPTH = 8
MAX_LIST = 20000      # entries read per directory
MAX_TREE = 300       # entries shown per directory in the file tree
STATS_BUDGET = 200000  # entries walked to size a folder
STATS_TTL = 10       # seconds folder sizes are cached
NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,159}$")
CONFIDENCE = {"high", "medium", "low"}

CSP = (
    "default-src 'none'; script-src 'self'; style-src 'self'; "
    "img-src 'self' data:; connect-src 'self'; base-uri 'none'; "
    "form-action 'none'; frame-ancestors 'none'"
)

MD = MarkdownIt("commonmark", {"html": False, "linkify": False}).enable(
    ["table", "strikethrough"]
)


def esc(value):
    return html.escape(str(value), quote=True)


def _no_images(self, tokens, idx, options, env):
    # Never load anything an agent pointed at (CSP blocks it too).
    return esc(f"[image: {tokens[idx].content}]")


def _link_open(self, tokens, idx, options, env):
    # Only in-page links stay clickable; any other URL is shown as text, so an
    # agent can't plant a live link to e.g. a LAN device's admin page.
    href = tokens[idx].attrGet("href") or ""
    stack = env.setdefault("links", [])
    if href.startswith("#") and re.match(r"^#[A-Za-z0-9_-]*$", href):
        stack.append(None)
        return f'<a href="{esc(href)}">'
    stack.append(href)
    return '<span class="ext">'


def _link_close(self, tokens, idx, options, env):
    stack = env.setdefault("links", [])
    href = stack.pop() if stack else None
    if href is None:
        return "</a>"
    return f'</span> <code class="url">{esc(href)}</code>'


MD.add_render_rule("image", _no_images)
MD.add_render_rule("link_open", _link_open)
MD.add_render_rule("link_close", _link_close)


def qpath(part):
    """URL-quote a path component, including undecodable (surrogate) bytes."""
    return urllib.parse.quote(os.fsencode(part), safe="")


# --------------------------------------------------------------------------
# Safe filesystem access below the cases root (no symlinks anywhere).


def valid_part(part):
    return part not in ("", ".", "..") and "/" not in part and "\0" not in part


def open_below(root, parts, flags=os.O_RDONLY):
    """Open root/parts... refusing symlinks in every component."""
    if not all(valid_part(p) for p in parts):
        raise PermissionError("bad path")
    fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        for part in parts[:-1]:
            nfd = os.open(
                part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd
            )
            os.close(fd)
            fd = nfd
        if not parts:
            return os.dup(fd)
        return os.open(parts[-1], flags | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=fd)
    finally:
        os.close(fd)


def read_file(root, parts, limit=MAX_TEXT):
    try:
        fd = open_below(root, parts)
    except OSError:
        return None
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            return None
        chunks, total = [], 0
        while total < limit:
            chunk = os.read(fd, min(65536, limit - total))
            if not chunk:
                break
            chunks.append(chunk)
            total += len(chunk)
        return b"".join(chunks)
    finally:
        os.close(fd)


def read_json(root, parts):
    data = read_file(root, parts)
    if data is None:
        return None
    try:
        return json.loads(data.decode("utf-8", "replace"))
    except (ValueError, RecursionError):
        return {"_invalid": True}


def stat_below(root, parts):
    try:
        fd = open_below(root, parts, os.O_RDONLY)
    except OSError:
        return None
    try:
        return os.fstat(fd)
    finally:
        os.close(fd)


def list_cases(root):
    try:
        fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    except OSError:
        return []
    try:
        names = []
        with os.scandir(fd) as it:
            for entry in it:
                if NAME_RE.match(entry.name) and entry.is_dir(follow_symlinks=False):
                    names.append(entry.name)
    finally:
        os.close(fd)
    return [n for n in names if stat_below(root, [n, "case.json"]) is not None]


def list_dir(root, parts):
    """Entries of root/parts as (name, is_dir, size); no symlinks, no specials."""
    try:
        fd = open_below(root, parts, os.O_RDONLY | os.O_DIRECTORY)
    except OSError:
        return []
    out = []
    try:
        with os.scandir(fd) as it:
            for entry in it:
                if len(out) >= MAX_LIST:
                    break
                if not valid_part(entry.name):
                    continue
                if entry.is_dir(follow_symlinks=False):
                    out.append((entry.name, True, 0))
                elif entry.is_file(follow_symlinks=False):
                    out.append((entry.name, False, entry.stat(follow_symlinks=False).st_size))
    finally:
        os.close(fd)
    out.sort(key=lambda e: (not e[1], natural(e[0])))
    return out


def natural(name):
    """Sort key: pkg2 before pkg10."""
    return [(0, int(t), "") if t.isdigit() else (1, 0, t.lower())
            for t in re.split(r"(\d+)", name)]


_STATS = {}


def tree_stats(root, parts):
    """(files, bytes, complete) below root/parts, budget-limited, cached briefly."""
    key = (root, tuple(parts))
    hit = _STATS.get(key)
    now = time.monotonic()
    if hit and now - hit[0] < STATS_TTL:
        return hit[1]
    files, size, seen = 0, 0, 0
    stack = [(list(parts), 0)]
    complete = True
    while stack:
        cur, depth = stack.pop()
        if depth > MAX_DEPTH:
            complete = False
            continue
        try:
            fd = open_below(root, cur, os.O_RDONLY | os.O_DIRECTORY)
        except OSError:
            continue
        try:
            with os.scandir(fd) as it:
                for entry in it:
                    seen += 1
                    if seen > STATS_BUDGET:
                        complete = False
                        break
                    if not valid_part(entry.name):
                        continue
                    if entry.is_dir(follow_symlinks=False):
                        stack.append((cur + [entry.name], depth + 1))
                    elif entry.is_file(follow_symlinks=False):
                        files += 1
                        size += entry.stat(follow_symlinks=False).st_size
        finally:
            os.close(fd)
        if seen > STATS_BUDGET:
            break
    result = (files, size, complete)
    if len(_STATS) > 2000:
        _STATS.clear()
    _STATS[key] = (now, result)
    return result


def fingerprint(root, case=None):
    h = hashlib.sha256()
    for name in sorted([case] if case else list_cases(root)):
        for parts in ([name], [name, "case.json"], [name, "findings.json"],
                      [name, "notes.md"], [name, "artifacts"], [name, "scripts"]):
            st = stat_below(root, parts)
            if st is not None:
                h.update(f"{'/'.join(parts)}:{st.st_mtime_ns}:{st.st_size};".encode())
    return h.hexdigest()[:16]


def case_mtime(root, name):
    times = [
        st.st_mtime
        for st in (
            stat_below(root, [name, f]) for f in ("case.json", "findings.json", "notes.md")
        )
        if st is not None
    ]
    return max(times) if times else 0


# --------------------------------------------------------------------------
# Rendering helpers


def human_size(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1000 or unit == "GB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1000
    return f"{n:.1f} GB"


def human_count(n):
    return f"{n / 1000:.1f}k" if n >= 10000 else f"{n:,}"


def ago(ts):
    if not ts:
        return "never"
    d = max(0, time.time() - ts)
    if d < 60:
        return "just now"
    if d < 3600:
        return f"{int(d // 60)} min ago"
    if d < 86400:
        return f"{int(d // 3600)} h ago"
    return time.strftime("%Y-%m-%d %H:%M", time.localtime(ts))


def as_text(value):
    if isinstance(value, str):
        return value
    if value is None:
        return ""
    return json.dumps(value, ensure_ascii=False)


def as_list(value):
    return value if isinstance(value, list) else []


def plain(text):
    """Markdown-ish text flattened for one-line previews (escaped later)."""
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", as_text(text))
    text = re.sub(r"[*_`#>]+", "", text)
    return " ".join(text.split())


def md(text, limit=MAX_TEXT):
    text = as_text(text)
    note = ""
    if len(text) > limit:
        text = text[-limit:]
        note = f'<p class="hint">Showing the last {limit // 1024} KiB.</p>'
    return note + MD.render(text, {})


def slug(s):
    return re.sub(r"[^a-z0-9-]", "", s.lower())[:24] or "x"


def status_badge(status):
    s = as_text(status) or "new"
    return f'<span class="badge status-{slug(s)}">{esc(s)}</span>'


LONG_KEYS = {"description", "purpose", "evidence", "behavior", "notes"}
CODE_KEYS = {"address", "endpoint", "path", "file", "location", "value", "sha256"}


def cell(key, value):
    text = as_text(value)
    if key == "confidence" and text.lower() in CONFIDENCE:
        return f'<td class="c-conf"><span class="conf conf-{text.lower()}">{esc(text)}</span></td>'
    shown = text if len(text) <= 400 else text[:400] + "…"
    title = f' title="{esc(text[:2000])}"' if len(text) > 60 else ""
    if key == "endpoint":  # the point of the table: show it whole, wrapped
        return f'<td class="c-wrap"><code>{esc(shown)}</code></td>'
    if key in CODE_KEYS:
        return f'<td class="c-code"{title}><code>{esc(shown)}</code></td>'
    cls = "c-long" if key in LONG_KEYS else "c-text"
    return f'<td class="{cls}"{title}><div class="clamp">{esc(shown)}</div></td>'


def table(rows, keys=None):
    rows = [r for r in as_list(rows) if isinstance(r, dict)]
    total = len(rows)
    rows = rows[:MAX_ROWS]
    if keys is None:
        keys = []
        for row in rows:
            for k in row:
                if k not in keys and len(keys) < 8:
                    keys.append(k)
    head = "".join(f"<th>{esc(k.replace('_', ' '))}</th>" for k in keys)
    body = "".join(
        "<tr>" + "".join(cell(k, r.get(k, "")) for k in keys) + "</tr>" for r in rows
    )
    more = f'<p class="hint">Showing {MAX_ROWS} of {total}.</p>' if total > MAX_ROWS else ""
    return (
        f'<div class="table-wrap"><table><thead><tr>{head}</tr></thead>'
        f"<tbody>{body}</tbody></table></div>{more}"
    )


def card(anchor, title, inner, count=None, cls="", collapsible=False, open_=True):
    badge = f'<span class="count">{count}</span>' if count is not None else ""
    head = f"<h2>{esc(title)}{badge}</h2>"
    if collapsible:
        return (
            f'<section id="{anchor}" class="card {cls}"><details class="fold"{" open" if open_ else ""}>'
            f"<summary>{head}</summary>{inner}</details></section>"
        )
    return f'<section id="{anchor}" class="card {cls}">{head}{inner}</section>'


def page(title, body, live_key, crumbs=""):
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<title>{esc(title)} · REA</title>
<link rel="stylesheet" href="/static/style.css">
<script src="/static/app.js" defer></script>
</head><body data-live="{esc(live_key)}">
<header class="top"><nav><a href="/" class="brand">REA</a>{crumbs}</nav>
<span id="live" class="live" title="Updates automatically">live</span></header>
<main>{body}</main></body></html>"""


# --------------------------------------------------------------------------
# Index


def render_card(root, name):
    f = read_json(root, [name, "findings.json"]) or {}
    c = read_json(root, [name, "case.json"]) or {}
    if not isinstance(f, dict):
        f = {}
    if not isinstance(c, dict):
        c = {}
    summary = plain(f.get("summary", ""))
    highlights = as_list(f.get("highlights"))
    chips = []
    for key, label in (("network", "endpoints"), ("functions", "functions"),
                       ("behaviors", "behaviors"), ("open_questions", "open questions")):
        n = len(as_list(f.get(key)))
        if n:
            chips.append(f'<span class="chip"><b>{n}</b> {label}</span>')
    hl = "".join(f"<li>{esc(as_text(h)[:200])}</li>" for h in highlights[:3])
    search_blob = " ".join([name, as_text(f.get("title", "")), summary[:2000]]
                           + [as_text(h) for h in highlights[:20]])
    status = slug(as_text(f.get("status")) or "new")
    return (
        f'<a class="case-card st-{status}" href="/case/{qpath(name)}/" data-search="{esc(search_blob.lower())}">'
        f'<div class="cc-head"><h2>{esc(case_title(f, c, name)[:200])}</h2>'
        f'{status_badge(f.get("status"))}</div>'
        f'<p class="cc-summary">{esc(summary[:500]) or "<span class=muted>No summary yet.</span>"}</p>'
        f'{"<ul class=cc-hl>" + hl + "</ul>" if hl else ""}'
        f'<div class="cc-foot"><div class="chips">{"".join(chips)}</div>'
        f'<span class="muted">{esc(ago(case_mtime(root, name)))}</span></div></a>'
    )


def render_index(root):
    cases = sorted(list_cases(root), key=lambda n: case_mtime(root, n), reverse=True)
    cards = []
    for name in cases:
        try:  # one broken case must not take the index down
            cards.append(render_card(root, name))
        except Exception as exc:
            print(f"rea-report: card {name!r}: {exc!r}", file=sys.stderr)
            cards.append(
                f'<a class="case-card" href="/case/{qpath(name)}/"><div class="cc-head">'
                f'<h2>{esc(name)}</h2></div><p class="cc-summary">Could not render this case.</p></a>'
            )
    empty = (
        '<div class="empty-state"><h2>No cases yet</h2><p>Run <code>rea path/to/target</code> '
        "on the desktop, or ask the agent to start one.</p></div>"
    )
    body = (
        f'<div class="page-head"><div><h1>Cases</h1><p class="muted">{len(cases)} '
        f'case{"s" if len(cases) != 1 else ""} in ~/rea</p></div>'
        '<input id="search" type="search" placeholder="Search notes and findings…" autocomplete="off"></div>'
        '<div id="results" class="results" hidden></div>'
        f'<div class="case-grid">{"".join(cards) or empty}</div>'
    )
    return page("Cases", body, "")


# --------------------------------------------------------------------------
# Case dashboard

STEPS = ["triage", "mapping", "deep-dive", "verifying", "done"]


def stepper(status):
    s = slug(as_text(status) or "new")
    idx = STEPS.index(s) if s in STEPS else -1
    items = []
    for i, step in enumerate(STEPS):
        state = "done" if i < idx or s == "done" else ("now" if i == idx else "todo")
        items.append(f'<li class="step-{state}"><span></span>{esc(step)}</li>')
    return f'<ol class="stepper">{"".join(items)}</ol>'


def kpis(f, art_files, art_bytes):
    tiles = []
    for key, label, tab in (("network", "Endpoints", "findings"),
                            ("behaviors", "Behaviors", "findings"),
                            ("functions", "Functions", "findings"),
                            ("components", "Components", "findings"),
                            ("secrets", "Secrets", "findings"),
                            ("open_questions", "Open questions", "overview")):
        n = len(as_list(f.get(key)))
        tiles.append(
            f'<a class="kpi{" kpi-zero" if not n else ""}" href="#{tab}" data-tab="{tab}" data-jump="sec-{key}">'
            f'<b>{n}</b><span>{label}</span></a>'
        )
    tiles.append(
        f'<a class="kpi" href="#files" data-tab="files"><b>{human_count(art_files)}</b>'
        f'<span>Files · {esc(human_size(art_bytes))}</span></a>'
    )
    return f'<div class="kpis">{"".join(tiles)}</div>'


def split_notes(text):
    """('## ' sections of a notes.md log, text before the first section)."""
    parts = re.split(r"(?m)^(?=## )", text)
    sections = [p for p in parts if p.startswith("## ")]
    head = "".join(p for p in parts if not p.startswith("## "))
    return sections, head


def tree_entries(root, case, rel):
    """JSON-able listing of case/rel for the artifact tree."""
    out = []
    entries = list_dir(root, [case] + rel)
    for name, is_dir, size in entries[:MAX_TREE]:
        href = "/case/" + qpath(case) + "/file/" + "/".join(qpath(p) for p in rel + [name])
        item = {"name": name, "path": "/".join(rel + [name]), "dir": is_dir}
        if is_dir:
            files, nbytes, complete = tree_stats(root, [case] + rel + [name])
            item.update(files=files, size=human_size(nbytes), approx=not complete)
        else:
            item.update(size=human_size(size), href=href)
        out.append(item)
    return {"entries": out, "more": max(0, len(entries) - MAX_TREE)}


def tree_html(root, case, rel):
    """Server-rendered first level of the tree (deeper levels load on open)."""
    listing = tree_entries(root, case, rel)
    rows = []
    for e in listing["entries"]:
        if e["dir"]:
            approx = "≥ " if e["approx"] else ""
            rows.append(
                f'<li><details class="dir" data-path="{esc(e["path"])}"><summary>'
                f'<span class="ico">▸</span><span class="nm">{esc(e["name"])}/</span>'
                f'<span class="meta">{approx}{esc(human_count(e["files"]))} file{"" if e["files"] == 1 else "s"} · {esc(e["size"])}</span>'
                f'</summary><ul class="tree"></ul></details></li>'
            )
        else:
            rows.append(
                f'<li class="file"><a href="{esc(e["href"])}" download>{esc(e["name"])}</a>'
                f'<span class="meta">{esc(e["size"])}</span></li>'
            )
    if listing["more"]:
        rows.append(f'<li class="more">+{listing["more"]} more</li>')
    if not rows:
        rows.append('<li class="more">empty</li>')
    return f'<ul class="tree" data-case="{esc(case)}">{"".join(rows)}</ul>'


def case_title(f, c, name):
    """findings title, else case.json title, else the case folder name -
    never the bare source folder (e.g. "apks")."""
    t = as_text(f.get("title"))
    if t and t != as_text(c.get("source")):
        return t
    return as_text(c.get("title")) or t or name


FINDING_SECTIONS = (
    ("network", "Network endpoints", "Where it connects and why",
     ["endpoint", "protocol", "direction", "purpose", "evidence", "confidence"]),
    ("behaviors", "Behaviors", "What it does",
     ["behavior", "evidence", "confidence"]),
    ("functions", "Functions", "Code locations that matter",
     ["name", "address", "file", "purpose", "evidence", "confidence"]),
    ("components", "Components", "Binaries, apps, services and modules involved",
     ["name", "kind", "path", "description", "evidence"]),
    ("secrets", "Secrets", "Keys, tokens and credentials found",
     ["kind", "location", "value", "evidence"]),
)


def section_table(rows, cols):
    present = [k for k in cols if any(isinstance(r, dict) and k in r for r in rows)]
    extra = []
    for r in rows:
        if isinstance(r, dict):
            for k in r:
                if k not in present and k not in extra and len(present) + len(extra) < 8:
                    extra.append(k)
    return table(rows, present + extra)


def render_case(root, name):
    f = read_json(root, [name, "findings.json"])
    c = read_json(root, [name, "case.json"]) or {}
    notes = read_file(root, [name, "notes.md"])
    if not isinstance(c, dict):
        c = {}
    invalid = not isinstance(f, dict) or f.get("_invalid")
    if not isinstance(f, dict):
        f = {}

    title = case_title(f, c, name)[:200]
    a_files, a_bytes, _ = tree_stats(root, [name, "artifacts"])
    s_files, s_bytes, _ = tree_stats(root, [name, "scripts"])
    n_files, n_bytes = a_files + s_files, a_bytes + s_bytes
    notes_text = notes.decode("utf-8", "replace") if notes is not None else ""
    sections, notes_head = split_notes(notes_text)

    head = (
        f'<div class="case-head"><div><h1>{esc(title)}</h1>'
        f'<p class="muted"><code>{esc(name)}</code> · created {esc(as_text(c.get("created", "?"))[:16].replace("T", " "))}'
        f" · updated {esc(ago(case_mtime(root, name)))}</p></div>{status_badge(f.get('status'))}</div>"
    )
    warn = '<div class="warn">findings.json is missing or not valid JSON right now.</div>' if invalid else ""

    # --- Overview ---
    summary = f.get("summary")
    hl = as_list(f.get("highlights"))
    if summary or hl:
        inner = f'<div class="summary">{md(summary)}</div>' if summary else ""
        if hl:
            inner += '<h3 class="sub">Key findings</h3><ol class="key-findings">' + "".join(
                f"<li>{esc(as_text(h))}</li>" for h in hl[:MAX_ROWS]) + "</ol>"
        ov_main = card("summary", "Summary", inner, cls="card-summary")
    else:
        latest = sections[-1] if sections else ""
        ov_main = card("summary", "Summary", (
            '<p class="muted">No structured findings yet - the agent fills this in as it works.</p>'
            + (f'<h3 class="sub">Latest note</h3><div class="notes">{md(latest)}</div>' if latest else "")))
    qs = as_list(f.get("open_questions"))
    nxt = as_list(f.get("next_steps"))
    ov_side = [card("progress", "Progress", stepper(f.get("status")), cls="card-side")]
    ov_side.append(card("sec-open_questions", "Open questions", (
        '<ul class="qlist">' + "".join(f"<li>{esc(as_text(q))}</li>" for q in qs[:MAX_ROWS]) + "</ul>"
    ) if qs else '<p class="muted">None yet.</p>', len(qs) if qs else None, cls="card-side"))
    ov_side.append(card("next", "Next steps", (
        '<ul class="nlist">' + "".join(f"<li>{esc(as_text(q))}</li>" for q in nxt[:MAX_ROWS]) + "</ul>"
    ) if nxt else '<p class="muted">None yet.</p>', len(nxt) if nxt else None, cls="card-side"))
    overview = (
        kpis(f, n_files, n_bytes)
        + f'<div class="layout"><div class="col-main">{ov_main}</div>'
        f'<aside class="col-side">{"".join(ov_side)}</aside></div>'
    )

    # --- Findings ---
    fcards, fnav = [], []
    for key, label, blurb, cols in FINDING_SECTIONS:
        rows = [r for r in as_list(f.get(key)) if isinstance(r, dict)]
        fnav.append(f'<a href="#findings" data-jump="sec-{key}" class="{"" if rows else "empty"}">'
                    f'{esc(label)} <span class="count">{len(rows)}</span></a>')
        inner = f'<p class="hint">{esc(blurb)}</p>' + (
            section_table(rows, cols) if rows else '<p class="muted">Nothing recorded yet.</p>')
        fcards.append(card(f"sec-{key}", label, inner, len(rows)))
    known = {"schema", "title", "status", "summary", "highlights", "components", "functions",
             "network", "behaviors", "secrets", "open_questions", "next_steps", "_invalid"}
    for key, value in f.items():
        if key in known:
            continue
        label = key.replace("_", " ").title()
        anchor = "sec-x-" + slug(key)
        fnav.append(f'<a href="#findings" data-jump="{anchor}">{esc(label)}</a>')
        if isinstance(value, list) and value and all(isinstance(v, dict) for v in value):
            fcards.append(card(anchor, label, table(value), len(value)))
        else:
            fcards.append(card(anchor, label, "<pre>" + esc(json.dumps(
                value, indent=2, ensure_ascii=False)[:200000]) + "</pre>"))
    findings = f'<nav class="subnav">{"".join(fnav)}</nav><div class="stack">{"".join(fcards)}</div>'

    # --- Notes (newest first) ---
    if sections:
        shown = sections[::-1]
        size = 0
        kept = []
        for s in shown:
            size += len(s)
            if size > MAX_NOTES and kept:
                break
            kept.append(s)
        more = (f'<p class="hint">Showing the newest {len(kept)} of {len(sections)} entries.</p>'
                if len(kept) < len(sections) else "")
        notes_html = "".join(
            f'<article class="card note-entry">{md(s)}</article>' for s in kept) + more
        if notes_head.strip():
            notes_html += f'<article class="card note-entry note-head">{md(notes_head, MAX_NOTES)}</article>'
    elif notes_text.strip():
        notes_html = f'<article class="card note-entry">{md(notes_text, MAX_NOTES)}</article>'
    else:
        notes_html = '<div class="card"><p class="muted">No notes yet.</p></div>'
    notes_tab = f'<p class="hint">The agent\'s running log, newest first.</p><div class="stack">{notes_html}</div>'

    # --- Files ---
    files_inner = tree_html(root, name, ["artifacts"])
    if s_files:
        files_inner += '<h3 class="sub">scripts/</h3>' + tree_html(root, name, ["scripts"])
    files_tab = card("files-card", "Files the agent produced", (
        '<p class="hint">Extracted, decompiled and captured data under <code>artifacts/</code> '
        'and helper scripts. Produced inside the VM: downloads only, treat as untrusted.</p>'
        + files_inner), f"{human_count(n_files)} · {human_size(n_bytes)}")

    # --- Case ---
    targets = [t for t in as_list(c.get("targets")) if isinstance(t, dict)]
    if targets:
        trows = "".join(
            f'<tr><td class="c-code" title="{esc(as_text(t.get("path")))}"><code>{esc(as_text(t.get("path")))}</code></td>'
            f'<td class="c-text"><div class="clamp">{esc(as_text(t.get("type"))[:120])}</div></td>'
            f'<td class="num">{esc(human_size(t.get("size")) if isinstance(t.get("size"), int) else "?")}</td>'
            f'<td class="c-hash"><code title="{esc(as_text(t.get("sha256")))}">{esc(as_text(t.get("sha256")))}</code></td></tr>'
            for t in targets[:MAX_ROWS]
        )
        ttable = ('<div class="table-wrap"><table><thead><tr><th>file</th><th>type</th><th>size</th>'
                  f'<th>sha256</th></tr></thead><tbody>{trows}</tbody></table></div>')
    else:
        ttable = '<p class="muted">Not inventoried yet.</p>'
    info = "".join(
        f"<dt>{esc(k)}</dt><dd>{v}</dd>" for k, v in (
            ("Case folder", f"<code>~/rea/{esc(name)}</code>"),
            ("Created", esc(as_text(c.get("created", "?"))[:19].replace("T", " "))),
            ("Source", f"<code>{esc(as_text(c.get('source')))}</code>"),
            ("Status", status_badge(f.get("status"))),
        ))
    case_tab = (
        card("case-info", "Case", f'<dl class="facts">{info}</dl>')
        + card("targets", "What was analysed", (
            '<p class="hint">The original files given to the agent, copied read-only into '
            '<code>target/</code>, with hashes so findings can be tied to exact inputs.</p>' + ttable),
            len(targets))
    )

    tabs = (("overview", "Overview", None), ("findings", "Findings",
            sum(len(as_list(f.get(k))) for k, *_ in FINDING_SECTIONS)),
            ("notes", "Notes", len(sections) or None), ("files", "Files", human_count(n_files)),
            ("case", "Case", None))
    tabbar = '<nav class="tabs" role="tablist">' + "".join(
        f'<a href="#{t}" data-tab="{t}" role="tab">{esc(label)}'
        f'{f"<span class=count>{n}</span>" if n else ""}</a>' for t, label, n in tabs) + "</nav>"
    panels = "".join(
        f'<section class="tab-panel" id="tab-{t}" data-panel="{t}">{content}</section>'
        for t, content in (("overview", overview), ("findings", findings), ("notes", notes_tab),
                           ("files", files_tab), ("case", case_tab)))
    body = head + warn + tabbar + panels
    crumbs = f'<span class="sep">/</span><span class="crumb">{esc(title)}</span>'
    return page(title, body, name, crumbs)


def search(root, query):
    query = query.strip().lower()[:200]
    if len(query) < 2:
        return []
    hits = []
    for name in list_cases(root):
        for fname in ("notes.md", "findings.json"):
            data = read_file(root, [name, fname])
            if data is None:
                continue
            text = data.decode("utf-8", "replace")
            low = text.lower()
            start, count = 0, 0
            while count < 5 and len(hits) < 100:
                i = low.find(query, start)
                if i < 0:
                    break
                a, b = max(0, i - 80), min(len(text), i + len(query) + 80)
                hits.append({"case": name, "href": "/case/" + qpath(name) + "/#"
                             + ("notes" if fname == "notes.md" else "summary"),
                             "file": fname, "snippet": " ".join(text[a:b].split())})
                start, count = i + len(query), count + 1
    return hits


# --------------------------------------------------------------------------
# HTTP


class Handler(BaseHTTPRequestHandler):
    server_version = "rea-report"
    sys_version = ""

    def log_message(self, fmt, *args):
        pass

    def headers_out(self, status, ctype, length, extra=None):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(length))
        self.send_header("Content-Security-Policy", CSP)
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()

    def send(self, status, body, ctype, extra=None):
        # backslashreplace: lone surrogates from hostile JSON or undecodable
        # filenames must not crash the response.
        data = body.encode("utf-8", "backslashreplace") if isinstance(body, str) else body
        self.headers_out(status, ctype, len(data), extra)
        self.wfile.write(data)

    def send_json(self, obj):
        # ensure_ascii: surrogates become \udcxx escapes, never raw bytes
        return self.send(HTTPStatus.OK, json.dumps(obj), "application/json")

    def send_download(self, root, parts, limit):
        """Stream a regular file (no symlinks) as an attachment."""
        try:
            fd = open_below(root, parts)
        except OSError:
            return False
        try:
            st = os.fstat(fd)
            if not stat.S_ISREG(st.st_mode):
                return False
            if st.st_size > limit:
                self.send(HTTPStatus.REQUEST_ENTITY_TOO_LARGE,
                          "File too large for the report; get it from ~/rea directly.", "text/plain")
                return True
            fname = re.sub(r"[^A-Za-z0-9._-]", "_", parts[-1])[:100] or "file"
            self.headers_out(HTTPStatus.OK, "application/octet-stream", st.st_size, {
                "Content-Disposition": f'attachment; filename="{fname}"'})
            remaining = st.st_size
            while remaining > 0:
                chunk = os.read(fd, min(1 << 20, remaining))
                if not chunk:
                    break
                self.wfile.write(chunk)
                remaining -= len(chunk)
            if remaining > 0:  # file shrank meanwhile; length can't be honoured
                self.close_connection = True
            return True
        finally:
            os.close(fd)

    def do_GET(self):  # noqa: N802
        cfg = self.server.cfg
        # Only ever answer to our own origin (blocks DNS rebinding).
        if self.headers.get("Host") not in cfg["hosts"]:
            return self.send(HTTPStatus.FORBIDDEN, "forbidden", "text/plain")
        url = urllib.parse.urlsplit(self.path)
        # surrogateescape: round-trips undecodable filename bytes to os.open
        path = urllib.parse.unquote(url.path, errors="surrogateescape")
        qs = urllib.parse.parse_qs(url.query, errors="surrogateescape")
        root = cfg["root"]
        try:
            if path == "/":
                return self.send(HTTPStatus.OK, render_index(root), "text/html; charset=utf-8")
            if path in ("/static/app.js", "/static/style.css"):
                fname = path.rsplit("/", 1)[1]
                ctype = "text/javascript" if fname.endswith(".js") else "text/css"
                with open(os.path.join(cfg["static"], fname), "rb") as fh:
                    return self.send(HTTPStatus.OK, fh.read(), ctype + "; charset=utf-8")
            if path == "/api/version":
                case = qs.get("case", [""])[0]
                if case and not NAME_RE.match(case):
                    case = ""
                v = fingerprint(root, case or None)
                if cfg["dev"]:  # also reload the page when the report's own code changes
                    v += ":" + ":".join(
                        str(os.stat(p).st_mtime_ns) for p in (
                            [os.path.abspath(__file__)]
                            + [os.path.join(cfg["static"], n) for n in sorted(os.listdir(cfg["static"]))]))
                return self.send_json({"v": v})
            if path == "/api/search":
                return self.send_json(search(root, qs.get("q", [""])[0]))
            m = re.match(r"^/case/([^/]+)/(?:(tree)|file/(.+))?$", path)
            if m and NAME_RE.match(m.group(1)) and m.group(1) in list_cases(root):
                name = m.group(1)
                if m.group(2):
                    rel = [p for p in qs.get("path", [""])[0].split("/") if p]
                    if (rel and rel[0] in ("artifacts", "scripts") and len(rel) <= MAX_DEPTH + 2
                            and all(valid_part(p) for p in rel)):
                        return self.send_json(tree_entries(root, name, rel))
                elif m.group(3) is None:
                    return self.send(HTTPStatus.OK, render_case(root, name), "text/html; charset=utf-8")
                else:
                    rel = m.group(3).split("/")
                    if rel[0] in ("artifacts", "scripts") and len(rel) <= MAX_DEPTH + 2:
                        if self.send_download(root, [name] + rel, cfg["max_download"]):
                            return None
            return self.send(HTTPStatus.NOT_FOUND, page("Not found", "<p>Not found.</p>", ""),
                             "text/html; charset=utf-8")
        except Exception as exc:  # never die on hostile input
            print(f"rea-report: {path!r}: {exc!r}", file=sys.stderr)
            return self.send(HTTPStatus.INTERNAL_SERVER_ERROR, "error", "text/plain")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", required=True, help="cases directory (~/rea)")
    ap.add_argument("--static", required=True)
    ap.add_argument("--port", type=int, default=8471)
    ap.add_argument("--max-download-mib", type=int, default=512)
    ap.add_argument("--dev", action="store_true",
                    help="reload open pages when this script or the static files change")
    args = ap.parse_args()

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.daemon_threads = True
    server.cfg = {
        "root": args.root,
        "static": args.static,
        "hosts": {f"127.0.0.1:{args.port}", f"localhost:{args.port}"},
        "max_download": args.max_download_mib * 1024 * 1024,
        "dev": args.dev,
    }
    print(f"rea-report: http://localhost:{args.port}/ serving {args.root}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()
