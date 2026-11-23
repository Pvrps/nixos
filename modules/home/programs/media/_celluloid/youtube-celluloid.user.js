// ==UserScript==
// @name        YouTube → Celluloid
// @namespace   nixos.celluloid
// @description Play the current video in Celluloid at the same timestamp; the tab jumps to where you stopped when Celluloid closes.
// @match       https://www.youtube.com/*
// @grant       GM_xmlhttpRequest
// @grant       GM_registerMenuCommand
// @connect     127.0.0.1
// @run-at      document-idle
// @noframes
// @version     @version@
// @downloadURL http://127.0.0.1:@port@/youtube-celluloid.user.js
// @updateURL   http://127.0.0.1:@port@/youtube-celluloid.user.js
// ==/UserScript==

// Managed by NixOS (modules/home/programs/media/celluloid.nix); edits made in
// Violentmonkey are overwritten on the next update.

(() => {
  "use strict";

  const LAUNCHER = "http://127.0.0.1:@port@/play";
  const BUTTON_ID = "celluloid-open-button";
  let busy = false;

  const videoId = () => {
    const url = new URL(location.href);
    if (url.pathname === "/watch") return url.searchParams.get("v");
    const m = url.pathname.match(/^\/(?:shorts|live)\/([A-Za-z0-9_-]{11})/);
    return m ? m[1] : null;
  };

  const player = () =>
    document.querySelector("#movie_player video.html5-main-video") ||
    document.querySelector("video");

  const setBusy = (on) => {
    busy = on;
    const button = document.getElementById(BUTTON_ID);
    if (button) {
      button.style.opacity = on ? "0.4" : "";
      button.title = on ? "Playing in Celluloid…" : "Play in Celluloid";
    }
  };

  const open = () => {
    const id = videoId();
    const video = player();
    if (busy || !id) return;

    const live = video && !Number.isFinite(video.duration);
    const start = video && !live ? video.currentTime : 0;
    if (video) video.pause();
    setBusy(true);

    GM_xmlhttpRequest({
      method: "POST",
      url: LAUNCHER,
      headers: {
        "Content-Type": "application/json",
        "X-Celluloid-Launcher": "1",
      },
      data: JSON.stringify({ id, t: start }),
      timeout: 0,
      onload: (res) => {
        setBusy(false);
        if (res.status !== 200) {
          console.warn("[celluloid] launcher answered", res.status);
          return;
        }
        const { position, ended } = JSON.parse(res.responseText);
        const v = player();
        // Only sync back if the tab still shows the same video.
        if (live || position == null || !v || videoId() !== id) return;
        v.currentTime = ended ? Math.max(0, v.duration - 1) : position;
        v.pause();
      },
      onerror: () => {
        setBusy(false);
        alert("Celluloid launcher is not running (systemctl --user status celluloid-launcher).");
      },
    });
  };

  // "Open in new" icon on a 24-unit grid. Sized like the reference (gear)
  // icon: same width/height attributes, and if its viewBox is larger than
  // 24 (older 36-unit player icons) the glyph is centred with the same
  // padding. YouTube enforces Trusted Types, so no innerHTML.
  const icon = (ref) => {
    const ns = "http://www.w3.org/2000/svg";
    const svg = document.createElementNS(ns, "svg");
    const vb = (ref && ref.getAttribute("viewBox") || "0 0 24 24").split(/[\s,]+/).map(Number);
    const size = vb.length === 4 && vb[2] > 24 ? vb[2] : 24;
    const pad = (size - 24) / 2;
    svg.setAttribute("viewBox", `${-pad} ${-pad} ${size} ${size}`);
    svg.setAttribute("width", (ref && ref.getAttribute("width")) || "100%");
    svg.setAttribute("height", (ref && ref.getAttribute("height")) || "100%");
    const path = document.createElementNS(ns, "path");
    path.setAttribute("fill", "currentColor");
    path.setAttribute(
      "d",
      "M19 19H5V5h7V3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2v-7h-2v7z" +
        "M14 3v2h3.59l-9.83 9.83 1.41 1.41L19 6.41V10h2V3h-7z",
    );
    svg.appendChild(path);
    return svg;
  };

  const addButton = () => {
    if (document.getElementById(BUTTON_ID) || !videoId()) return;
    // Sit right before the settings (gear) button, in the same group, so the
    // button gets the same spacing as YouTube's own whatever the layout.
    const gear = document.querySelector("#movie_player .ytp-settings-button");
    if (!gear || !gear.parentElement) return;
    const button = document.createElement("button");
    button.id = BUTTON_ID;
    button.className = "ytp-button";
    button.title = "Play in Celluloid";
    button.setAttribute("aria-label", "Play in Celluloid");
    button.appendChild(icon(gear.querySelector("svg")));
    button.addEventListener("click", (e) => {
      e.stopPropagation();
      open();
    });
    gear.parentElement.insertBefore(button, gear);
    setBusy(busy);
  };

  // YouTube is a single-page app that rebuilds the player controls.
  setInterval(addButton, 1000);
  addButton();
  GM_registerMenuCommand("Play in Celluloid", open);
})();
