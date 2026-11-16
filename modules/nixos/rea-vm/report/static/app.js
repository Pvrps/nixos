// rea-report client: live reload, lazy file tree, search. Served by
// rea_report.py under a strict CSP; all case data is inserted with
// textContent / attributes, never as HTML.
(() => {
  "use strict";
  const live = document.getElementById("live");
  const caseName = document.body.dataset.live || "";
  const versionUrl = "/api/version" + (caseName ? "?case=" + encodeURIComponent(caseName) : "");
  const stateKey = "rea-state:" + location.pathname;
  let version = null;

  // --- tabs (case page): #overview, #findings, ... kept in the URL ----------
  const panels = Array.from(document.querySelectorAll(".tab-panel"));
  function showTab(name, jump) {
    if (!panels.length) return;
    if (!panels.some((p) => p.dataset.panel === name)) name = panels[0].dataset.panel;
    for (const p of panels) p.hidden = p.dataset.panel !== name;
    for (const a of document.querySelectorAll(".tabs a")) {
      a.classList.toggle("active", a.dataset.tab === name);
    }
    if (jump) {
      const target = document.getElementById(jump);
      if (target) target.scrollIntoView({ block: "start" });
    }
  }
  if (panels.length) {
    showTab(location.hash.slice(1));
    window.addEventListener("hashchange", () => showTab(location.hash.slice(1)));
    document.addEventListener("click", (ev) => {
      const a = ev.target.closest("a[data-tab], a[data-jump]");
      if (!a) return;
      ev.preventDefault();
      const tab = a.dataset.tab || location.hash.slice(1);
      history.replaceState(null, "", "#" + tab);
      showTab(tab, a.dataset.jump);
    });
  }

  // --- file tree ----------------------------------------------------------
  function el(tag, cls, text) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text !== undefined) e.textContent = text;
    return e;
  }

  function fmtCount(n) {
    return n >= 10000 ? (n / 1000).toFixed(1) + "k" : n.toLocaleString();
  }

  function dirNode(entry) {
    const li = el("li");
    const d = el("details", "dir");
    d.dataset.path = entry.path;
    const s = el("summary");
    s.append(el("span", "ico", "▸"), el("span", "nm", entry.name + "/"),
      el("span", "meta", (entry.approx ? "≥ " : "") + fmtCount(entry.files)
        + (entry.files === 1 ? " file · " : " files · ") + entry.size));
    d.append(s, el("ul", "tree"));
    d.addEventListener("toggle", () => onToggle(d));
    li.append(d);
    return li;
  }

  function fileNode(entry) {
    const li = el("li", "file");
    const a = el("a", "", entry.name);
    a.href = entry.href;
    a.setAttribute("download", "");
    li.append(a, el("span", "meta", entry.size));
    return li;
  }

  async function loadDir(d) {
    const ul = d.querySelector(":scope > ul.tree");
    if (!ul || ul.dataset.loaded) return;
    ul.dataset.loaded = "1";
    ul.append(el("li", "more", "loading…"));
    try {
      const res = await fetch("/case/" + encodeURIComponent(caseName) + "/tree?path="
        + encodeURIComponent(d.dataset.path), { cache: "no-store" });
      const data = await res.json();
      ul.replaceChildren();
      for (const e of data.entries) ul.append(e.dir ? dirNode(e) : fileNode(e));
      if (data.more) ul.append(el("li", "more", "+" + data.more + " more"));
      if (!data.entries.length) ul.append(el("li", "more", "empty"));
    } catch (_) {
      ul.replaceChildren(el("li", "more", "could not load"));
      delete ul.dataset.loaded;
    }
  }

  function onToggle(d) {
    if (d.open) loadDir(d);
    saveState();
  }
  document.querySelectorAll("details.dir").forEach((d) => d.addEventListener("toggle", () => onToggle(d)));

  // --- keep open folders/sections and scroll across live reloads -----------
  function saveState() {
    const dirs = Array.from(document.querySelectorAll("details.dir[open]")).map((d) => d.dataset.path);
    const folds = Array.from(document.querySelectorAll("details.fold")).map((d) => d.open);
    sessionStorage.setItem(stateKey, JSON.stringify({ dirs, folds, y: window.scrollY }));
  }
  document.querySelectorAll("details.fold").forEach((d) => d.addEventListener("toggle", saveState));

  async function restoreState() {
    let st;
    try {
      st = JSON.parse(sessionStorage.getItem(stateKey) || "null");
    } catch (_) {
      st = null;
    }
    if (!st) return;
    const folds = document.querySelectorAll("details.fold");
    (st.folds || []).forEach((open, i) => { if (folds[i]) folds[i].open = open; });
    // Parents before children: open each path once its parent has loaded.
    for (const p of (st.dirs || []).sort((a, b) => a.length - b.length)) {
      const d = Array.from(document.querySelectorAll("details.dir")).find((x) => x.dataset.path === p);
      if (d) {
        d.open = true;
        await loadDir(d);
      }
    }
    window.scrollTo(0, st.y || 0);
  }
  restoreState();

  // --- live reload --------------------------------------------------------
  async function poll() {
    try {
      const res = await fetch(versionUrl, { cache: "no-store" });
      const { v } = await res.json();
      live.classList.remove("offline");
      if (version === null) {
        version = v;
      } else if (v !== version && !searching()) {
        saveState();
        location.reload();
        return;
      }
    } catch (_) {
      live.classList.add("offline");
    }
    setTimeout(poll, 2000);
  }
  poll();

  // --- search (index page) --------------------------------------------------
  const input = document.getElementById("search");
  const results = document.getElementById("results");
  function searching() {
    return input !== null && input.value.trim() !== "";
  }
  if (!input) return;

  const cards = Array.from(document.querySelectorAll(".case-card"));
  let timer = null;
  input.addEventListener("input", () => {
    const q = input.value.trim().toLowerCase();
    for (const c of cards) c.hidden = q !== "" && !(c.dataset.search || "").includes(q);
    clearTimeout(timer);
    timer = setTimeout(() => runSearch(q), 200);
  });

  async function runSearch(q) {
    results.replaceChildren();
    if (q.length < 2) {
      results.hidden = true;
      return;
    }
    const res = await fetch("/api/search?q=" + encodeURIComponent(q), { cache: "no-store" });
    const hits = await res.json();
    results.hidden = false;
    if (hits.length === 0) {
      results.append(el("p", "muted", "No matches in notes or findings."));
      return;
    }
    for (const h of hits) {
      const a = el("a", "hit");
      a.href = h.href;
      a.append(el("div", "hit-head", h.case + " · " + h.file), el("div", "hit-snippet", h.snippet));
      results.append(a);
    }
  }
})();
