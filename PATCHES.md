# System Patches, Workarounds, and Fixes

This document tracks programs in the NixOS configuration that require custom patches, workarounds, or fixes. Keeping track of these ensures they are periodically reviewed to see if upstream updates have made them obsolete.

## arRPC (`arrpc`)
* **What**: Custom source override, local patch, and systemd pre-start fetch script.
* **Why**: The official `arrpc` package lacks robust Linux/Proton game detection and can struggle with native executable paths. These overrides ensure Discord Rich Presence correctly identifies what games are running on Linux.
* **Last Revisited**: 2026-03-21
* **Related Files**:
  * `modules/home-manager/programs/arrpc.nix`: Overrides the official package source to use the `OpenAsar/arrpc` branch (PR #143). Also includes a systemd pre-start script to securely fetch the latest Discord detectable games database from Discord's API before the service starts.
  * `modules/home-manager/patches/arrpc.patch`: A local patch applied to the Javascript source to properly match Linux native executable paths versus Windows `.exe` paths.

## Bolt (RuneScape / Jagex Launcher)
* **What**: Java AWT/Swing environment variable overrides via Flatpak.
* **Why**: Required to fix critical UI rendering issues under Wayland compositors, such as incorrect window bounds, black bars, duplicate/split views when resizing, and improper DPI scaling.
* **Last Revisited**: 2026-03-21
* **Related Files**:
  * `modules/home-manager/programs/bolt.nix`: Applies Flatpak overrides (`_JAVA_AWT_WM_NONREPARENTING=1`, `sun.java2d.opengl=false`, `sun.java2d.xrender=false`, `sun.java2d.uiScale=2`) directly to the `com.adamcake.Bolt` app data directory. Also sets specific Niri window rules to handle maximized state for the client.

## OBS Studio
* **What**: Manual Flatpak plugin extraction workaround.
* **Why**: Standard Flatpak sandboxing makes it difficult to install third-party plugins that aren't officially packaged as Flatpak extensions. This workaround circumvents the sandbox to install the Multi-RTMP plugin.
* **Last Revisited**: 2026-03-21
* **Related Files**:
  * `modules/home-manager/programs/obs.nix`: Contains a custom script (`mkPlugin`) that manually downloads the `obs-multi-rtmp` `.deb` package, extracts it via `dpkg-deb`, and writes the `.so` and `.locale` files directly into the local user Flatpak plugin directory (`~/.var/app/com.obsproject.Studio/config/obs-studio/plugins`).

## Discord (Nixcord / Equibop)
* **What**: Screen share and codec workarounds.
* **Why**: Hardware encoding for VP8/VP9/AV1 frequently crashes or results in black screens when attempting to screen share under Wayland on Linux. Forcing a fallback to H.264 is necessary for stability.
* **Last Revisited**: 2026-03-21
* **Related Files**:
  * `home/users/purps/default.nix`: Explicitly enables `webScreenShareFixes` and manually disables the VP8, VP9, and AV1 codecs in the `nixcord` configuration to force H.264 fallback.
  * `modules/home-manager/programs/discord.nix`: Contains the base nixcord/equibop setup and Niri window rules that prevent the background updater from taking over the screen.

## Steam
* **What**: Window manager (Niri) notification toast workarounds.
* **Why**: Under Niri, Steam's popup notification toasts are treated as standard windows, causing them to hijack active tiling slots and disrupt the workspace layout.
* **Last Revisited**: 2026-03-21
* **Related Files**:
  * `modules/home-manager/programs/steam.nix`: Uses custom Niri `window-rule` configurations targeting the `notificationtoasts_\d+_desktop` title to force them to float at the bottom right of the screen, remove their focus rings, and block them from showing up on screencasts.
