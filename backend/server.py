#!/usr/bin/env python3
"""Backend для docker-homework-11: отдаёт JSON с данными студента
и содержимым изменяемого файла из Docker volume."""
import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

PORT = int(os.environ.get("PORT", "8000"))
DATA_FILE = Path(os.environ.get("DATA_FILE", "/data/message.txt"))
VARIANT = os.environ.get("VARIANT", "11")
PERSONAL_ID = os.environ.get("PERSONAL_ID", "unknown")

DEFAULT_MESSAGE = "Hello from the volume! Edit me and recreate the backend."


def ensure_data_file():
    """При первом запуске создаём файл в volume; существующий не трогаем."""
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not DATA_FILE.exists():
        DATA_FILE.write_text(DEFAULT_MESSAGE + "\n", encoding="utf-8")


def read_message():
    try:
        return DATA_FILE.read_text(encoding="utf-8").strip()
    except OSError as exc:
        return f"cannot read {DATA_FILE}: {exc}"


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            self._send(200, {"status": "ok"})
        elif path in ("/", "/api", "/api/"):
            self._send(200, {
                "name": "Данила",
                "surname": "Насибулин",
                "variant": VARIANT,
                "personal_id": PERSONAL_ID,
                "hostname": socket.gethostname(),
                "favorite_tool": "systemd",
                "message_from_volume": read_message(),
            })
        else:
            self._send(404, {"error": "not found", "path": path})

    def log_message(self, fmt, *args):
        print("backend: " + fmt % args, flush=True)


if __name__ == "__main__":
    ensure_data_file()
    print(f"backend: listening on 0.0.0.0:{PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()