#!/usr/bin/env python3
"""
drpc-daemon: holds a WebSocket connection to the arRPC bridge (ws://127.0.0.1:1337)
and sends the active profile's activity JSON to Discord.

The arRPC bridge (Vencord's WebRichPresence plugin) receives messages of the form:
  { "activity": { ...fields... }, "socketId": "drpc" }
and dispatches them via Discord's internal FluxDispatcher, which allows setting
ActivityType.STREAMING (type=1) — something the external IPC socket cannot do.

State files:
  ~/.local/share/discord-rpc/current   — active profile name (written by `drpc enable`)
  ~/.config/discord-rpc/profiles/      — profile JSON files

The daemon runs as a systemd user service. It is started by `drpc enable` and
stopped by `drpc disable`. When stopped, it sends a null activity to clear status.
"""

import asyncio
import json
import os
import signal
import sys
from pathlib import Path

BRIDGE_URL = "ws://127.0.0.1:1337"
PING_INTERVAL = 15  # seconds between keepalive pings
RECONNECT_DELAY = 5  # seconds before reconnect on error

STATE_FILE = Path.home() / ".local/share/discord-rpc/current"
PROFILES_DIR = Path.home() / ".config/discord-rpc/profiles"


def load_profile(name: str) -> dict | None:
    path = PROFILES_DIR / f"{name}.json"
    try:
        with open(path) as f:
            return json.load(f)
    except Exception as e:
        print(f"[drpc-daemon] Failed to load profile '{name}': {e}", file=sys.stderr)
        return None


def read_current_profile() -> str | None:
    try:
        name = STATE_FILE.read_text().strip()
        return name if name else None
    except FileNotFoundError:
        return None
    except Exception as e:
        print(f"[drpc-daemon] Failed to read state file: {e}", file=sys.stderr)
        return None


def build_payload(profile: dict) -> dict:
    """Build the arRPC bridge message from a profile dict."""
    activity = {k: v for k, v in profile.items() if v not in (None, "", [])}
    return {"activity": activity, "socketId": "drpc"}


def build_clear_payload() -> dict:
    return {"activity": None, "socketId": "drpc"}


# Global flag — set by SIGTERM/SIGINT to trigger clean shutdown
_shutdown = False
_ws_ref = None


def _handle_signal(sig, frame):
    global _shutdown
    _shutdown = True


signal.signal(signal.SIGTERM, _handle_signal)
signal.signal(signal.SIGINT, _handle_signal)


async def run():
    global _shutdown, _ws_ref

    # Import here so the module-level import error is clear
    try:
        import websockets
    except ImportError:
        print("[drpc-daemon] 'websockets' Python package not found.", file=sys.stderr)
        sys.exit(1)

    profile_name = read_current_profile()
    if not profile_name:
        print("[drpc-daemon] No active profile set. Exiting.", file=sys.stderr)
        sys.exit(1)

    profile = load_profile(profile_name)
    if not profile:
        print(f"[drpc-daemon] Profile '{profile_name}' not found. Exiting.", file=sys.stderr)
        sys.exit(1)

    payload = build_payload(profile)
    print(f"[drpc-daemon] Starting with profile: {profile_name}", file=sys.stderr)

    while not _shutdown:
        try:
            async with websockets.connect(
                BRIDGE_URL,
                ping_interval=None,  # we handle pings manually
                close_timeout=3,
            ) as ws:
                _ws_ref = ws
                print(f"[drpc-daemon] Connected to arRPC bridge.", file=sys.stderr)

                # Send the activity
                await ws.send(json.dumps(payload))
                print(f"[drpc-daemon] Activity sent.", file=sys.stderr)

                # Keep alive loop
                while not _shutdown:
                    try:
                        await asyncio.wait_for(ws.recv(), timeout=PING_INTERVAL)
                    except asyncio.TimeoutError:
                        # Send ping to keep connection alive
                        await ws.ping()
                    except websockets.exceptions.ConnectionClosed:
                        print("[drpc-daemon] Connection closed by server.", file=sys.stderr)
                        break

                # Send null activity before closing
                try:
                    await ws.send(json.dumps(build_clear_payload()))
                    await asyncio.sleep(0.2)
                except Exception:
                    pass

        except OSError as e:
            if _shutdown:
                break
            print(f"[drpc-daemon] Connection failed: {e}. Retrying in {RECONNECT_DELAY}s...", file=sys.stderr)
            await asyncio.sleep(RECONNECT_DELAY)
        except Exception as e:
            if _shutdown:
                break
            print(f"[drpc-daemon] Error: {e}. Retrying in {RECONNECT_DELAY}s...", file=sys.stderr)
            await asyncio.sleep(RECONNECT_DELAY)

    print("[drpc-daemon] Exiting.", file=sys.stderr)


asyncio.run(run())
