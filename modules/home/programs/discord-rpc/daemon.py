import asyncio
import json
import os
import secrets
import signal
import sys
from pathlib import Path

BRIDGE_PORT_RANGE = range(6463, 6473)
PING_INTERVAL = 15
RECONNECT_DELAY = 5

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


_shutdown = False
_ws_ref = None


def _handle_signal(sig, frame):
    global _shutdown
    _shutdown = True


signal.signal(signal.SIGTERM, _handle_signal)
signal.signal(signal.SIGINT, _handle_signal)


async def try_connect(app_id: str):
    import websockets

    for port in BRIDGE_PORT_RANGE:
        uri = f"ws://127.0.0.1:{port}?client_id={app_id}&v=1&encoding=json"
        try:
            ws = await websockets.connect(uri, ping_interval=None, close_timeout=3)
            print(f"[drpc-daemon] Connected to arRPC on port {port}", file=sys.stderr)
            return ws
        except OSError:
            continue
    return None


async def send_set_activity(ws, profile: dict):
    activity = {}
    for k, v in profile.items():
        if k == "application_id":
            continue
        if v not in (None, "", []):
            activity[k] = v

    payload = {
        "cmd": "SET_ACTIVITY",
        "args": {
            "pid": os.getpid(),
            "activity": activity,
        },
        "nonce": secrets.token_hex(16),
    }
    await ws.send(json.dumps(payload))
    print(f"[drpc-daemon] Activity sent.", file=sys.stderr)


async def send_clear_activity(ws):
    payload = {
        "cmd": "SET_ACTIVITY",
        "args": {
            "pid": os.getpid(),
            "activity": None,
        },
        "nonce": secrets.token_hex(16),
    }
    try:
        await ws.send(json.dumps(payload))
        print(f"[drpc-daemon] Activity cleared.", file=sys.stderr)
    except Exception:
        pass


async def run():
    global _shutdown, _ws_ref

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

    app_id = profile.get("application_id", "")
    if not app_id or app_id == "0":
        print(f"[drpc-daemon] WARNING: application_id is '{app_id}'. "
              f"Create a Discord app at https://discord.com/developers/applications "
              f"to get a valid ID.", file=sys.stderr)

    print(f"[drpc-daemon] Starting with profile: {profile_name}", file=sys.stderr)

    while not _shutdown:
        try:
            ws = await try_connect(app_id)
            if ws is None:
                if _shutdown:
                    break
                print(f"[drpc-daemon] No arRPC WebSocket available. "
                      f"Retrying in {RECONNECT_DELAY}s...", file=sys.stderr)
                await asyncio.sleep(RECONNECT_DELAY)
                continue

            _ws_ref = ws

            try:
                await asyncio.wait_for(ws.recv(), timeout=5)
                print(f"[drpc-daemon] Received READY from arRPC.", file=sys.stderr)
            except asyncio.TimeoutError:
                print(f"[drpc-daemon] Timed out waiting for READY, proceeding anyway.", file=sys.stderr)

            await send_set_activity(ws, profile)

            while not _shutdown:
                try:
                    await asyncio.wait_for(ws.recv(), timeout=PING_INTERVAL)
                except asyncio.TimeoutError:
                    await ws.ping()
                except websockets.exceptions.ConnectionClosed:
                    print("[drpc-daemon] Connection closed by server.", file=sys.stderr)
                    break

            await send_clear_activity(ws)
            await asyncio.sleep(0.2)

        except OSError as e:
            if _shutdown:
                break
            print(f"[drpc-daemon] Connection failed: {e}. "
                  f"Retrying in {RECONNECT_DELAY}s...", file=sys.stderr)
            await asyncio.sleep(RECONNECT_DELAY)
        except Exception as e:
            if _shutdown:
                break
            print(f"[drpc-daemon] Error: {e}. "
                  f"Retrying in {RECONNECT_DELAY}s...", file=sys.stderr)
            await asyncio.sleep(RECONNECT_DELAY)

    print("[drpc-daemon] Exiting.", file=sys.stderr)


asyncio.run(run())
