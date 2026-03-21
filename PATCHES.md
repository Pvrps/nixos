# System Patches, Workarounds, and Fixes

This document tracks programs in the NixOS configuration that require custom patches, workarounds, or fixes. Keeping track of these ensures they are periodically reviewed to see if upstream updates have made them obsolete.

## arRPC (`arrpc`)
* **What**: Custom source override, local patch, and systemd pre-start fetch script.
* **Why**: Overrides the official package to use the `OpenAsar/arrpc` branch (PR #143) to significantly improve Linux/Proton game detection. Includes a local patch (`arrpc.patch`) to properly match Linux native executables versus Windows `.exe` paths. Finally, a pre-start script fetches the latest Discord detectable games database securely from Discord's API before starting the service.
* **Last Revisited**: 2026-03-18

## Bolt (RuneScape / Jagex Launcher)
* **What**: Java AWT/Swing environment variable overrides via Flatpak.
* **Why**: Required to fix UI rendering issues under Wayland compositors. Sets `_JAVA_AWT_WM_NONREPARENTING=1` to allow Java to track its own window bounds correctly. Disables Java2D hardware acceleration (`sun.java2d.opengl=false`, `sun.java2d.xrender=false`) to fix a stale surface/split view problem when resizing. Prevents double DPI scaling with `sun.java2d.uiScale=2`.
* **Last Revisited**: 2026-03-04

## OBS Studio
* **What**: Manual Flatpak plugin extraction workaround.
* **Why**: Installs the `obs-multi-rtmp` plugin by manually downloading the `.deb` package, extracting it, and placing the `.so` and `.locale` files directly into the local user Flatpak directory (`~/.var/app/com.obsproject.Studio/config/obs-studio/plugins`). This circumvents standard Flatpak sandboxing without needing to build a proper Flatpak extension.
* **Last Revisited**: 2026-03-18

## Discord (Nixcord / Equibop)
* **What**: Screen share and codec workarounds.
* **Why**: Explicitly enables `webScreenShareFixes` and disables VP8, VP9, and AV1 codecs. This forces Discord to fall back to H.264, which is necessary to fix hardware encoding crashes or black screens when attempting to screen share on Wayland.
* **Last Revisited**: 2026-03-17

## DankMaterialShell
* **What**: Disabled calendar integration workaround.
* **Why**: Explicitly sets `enableCalendarEvents = false` due to a build failure with the `khal` package on the Nixpkgs unstable channel.
* **Last Revisited**: 2026-03-05

## Steam
* **What**: Window manager (Niri) notification toast workarounds.
* **Why**: Uses custom Niri window rules to prevent Steam notification toasts (`notificationtoasts_\d+_desktop`) from hijacking active tiling slots. It forces them to float at the bottom right of the screen, removes focus rings, and blocks them from showing up on screencasts.
* **Last Revisited**: 2026-03-05
