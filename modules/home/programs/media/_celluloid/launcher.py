"""Open YouTube videos in Celluloid at the browser's timestamp, and report
where playback stopped once Celluloid closes.

Used by youtube-celluloid.user.js (Violentmonkey). Listens on 127.0.0.1 only.

  GET  /youtube-celluloid.user.js   the userscript (install / auto-update)
  POST /play  {"id": "<video id>", "t": <seconds>}
       -> blocks until Celluloid exits, then
          {"position": <seconds or null>, "ended": <bool>}

Requests must carry the X-Celluloid-Launcher header (browsers only send
custom headers cross-origin after a CORS preflight, which is never granted)
and a localhost Host header (defeats DNS rebinding).
"""

import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CELLULOID = os.environ["CELLULOID"]
USERSCRIPT = os.environ["USERSCRIPT"]
PORT = int(os.environ["PORT"])

VIDEO_ID = re.compile(r"^[A-Za-z0-9_-]{11}$")
HOSTS = {f"127.0.0.1:{PORT}", f"localhost:{PORT}"}


class Mpv:
    """Minimal client for mpv's JSON IPC socket."""

    def __init__(self, path):
        self.path = path
        self.sock = None
        self.buf = b""
        self.req = 0

    def connect(self):
        if self.sock is None:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(2)
            s.connect(self.path)
            self.sock = s

    def get(self, prop):
        self.connect()
        self.req += 1
        msg = {"command": ["get_property", prop], "request_id": self.req}
        self.sock.sendall(json.dumps(msg).encode() + b"\n")
        while True:
            while b"\n" not in self.buf:
                chunk = self.sock.recv(65536)
                if not chunk:
                    raise ConnectionError("mpv closed the socket")
                self.buf += chunk
            line, self.buf = self.buf.split(b"\n", 1)
            reply = json.loads(line)
            if reply.get("request_id") == self.req:
                return reply.get("data") if reply.get("error") == "success" else None

    def close(self):
        if self.sock is not None:
            self.sock.close()
            self.sock = None


def play(video_id, start):
    """Run Celluloid until it exits; return (last position, reached end)."""
    with tempfile.TemporaryDirectory(prefix="celluloid-launcher-") as tmp:
        ipc = os.path.join(tmp, "mpv.sock")
        proc = subprocess.Popen(
            [
                CELLULOID,
                # Own instance: an existing window would drop the --mpv-*
                # options, and we need to know when this one closes.
                "--no-existing-session",
                f"--mpv-start={start:.3f}",
                f"--mpv-input-ipc-server={ipc}",
                "--",
                f"https://www.youtube.com/watch?v={video_id}",
            ],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        mpv = Mpv(ipc)
        position, ended = None, False
        while proc.poll() is None:
            try:
                pos = mpv.get("time-pos")
                if pos is not None:
                    position = pos
                    ended = bool(mpv.get("eof-reached"))
                elif position is not None and mpv.get("idle-active"):
                    # Celluloid unloads the file once it has played out.
                    ended = True
            except (OSError, ConnectionError, ValueError):
                mpv.close()
            time.sleep(1)
        mpv.close()
        return position, ended


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        sys.stderr.write(fmt % args + "\n")

    def reply(self, code, body=b"", ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def host_ok(self):
        return self.headers.get("Host", "") in HOSTS

    def do_GET(self):
        if not self.host_ok():
            return self.reply(403)
        if self.path == "/youtube-celluloid.user.js":
            with open(USERSCRIPT, "rb") as f:
                return self.reply(200, f.read(), "text/javascript; charset=utf-8")
        self.reply(404)

    def do_POST(self):
        if not self.host_ok() or self.headers.get("X-Celluloid-Launcher") != "1":
            return self.reply(403)
        if self.path != "/play":
            return self.reply(404)
        try:
            length = min(int(self.headers.get("Content-Length", "0")), 4096)
            req = json.loads(self.rfile.read(length))
            video_id = str(req["id"])
            start = max(0.0, float(req.get("t", 0)))
        except (ValueError, KeyError, TypeError):
            return self.reply(400)
        if not VIDEO_ID.match(video_id):
            return self.reply(400)

        position, ended = play(video_id, start)
        body = json.dumps({"position": position, "ended": ended}).encode()
        try:
            self.reply(200, body)
        except OSError:
            pass  # tab closed or navigated away meanwhile


def main():
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.daemon_threads = True
    server.serve_forever()


if __name__ == "__main__":
    main()
