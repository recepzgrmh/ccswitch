#!/usr/bin/env python3
"""
ccswitch Chrome Usage Bridge — native messaging host.

Started by Chrome when the ccswitch extension calls connectNative().
Listens on a Unix socket (~/.claude/ccswitch-helper.sock) for ccswitch CLI
requests, relays them to the Chrome extension, and returns the response.
"""
import json
import os
import socket
import struct
import sys
import threading
import uuid
from pathlib import Path

SOCK_PATH     = Path.home() / ".claude" / "ccswitch-helper.sock"
_lock         = threading.Lock()
_pending: dict = {}   # id → {"event": Event, "response": dict|None}


# ── Native messaging I/O (Chrome ↔ bridge) ────────────────────────────────────

def _nm_read():
    raw = sys.stdin.buffer.read(4)
    if len(raw) < 4:
        return None
    length = struct.unpack("=I", raw)[0]
    data = sys.stdin.buffer.read(length)
    return json.loads(data.decode()) if len(data) == length else None


def _nm_write(obj):
    data = json.dumps(obj, separators=(",", ":")).encode()
    sys.stdout.buffer.write(struct.pack("=I", len(data)) + data)
    sys.stdout.buffer.flush()


def _nm_reader():
    """Thread: read responses from extension, wake waiting CLI handlers."""
    while True:
        msg = _nm_read()
        if msg is None:
            os._exit(0)
        req_id = msg.get("id")
        if not req_id:
            continue
        with _lock:
            item = _pending.get(req_id)
            if item:
                item["response"] = msg
                item["event"].set()


# ── CLI request dispatch (socket → extension → socket) ───────────────────────

def _ask_extension(org_id: str) -> dict:
    req_id = str(uuid.uuid4())
    event  = threading.Event()
    with _lock:
        _pending[req_id] = {"event": event, "response": None}

    _nm_write({"id": req_id, "type": "get_usage", "org_id": org_id})

    timed_out = not event.wait(timeout=8)
    with _lock:
        item = _pending.pop(req_id, {})

    if timed_out:
        return {"ok": False, "error": "timeout_waiting_for_extension"}
    return item.get("response") or {"ok": False, "error": "empty_response"}


def _handle_client(conn: socket.socket):
    try:
        chunks = []
        while True:
            chunk = conn.recv(4096)
            if not chunk:
                break
            chunks.append(chunk)
        req    = json.loads(b"".join(chunks).decode())
        result = _ask_extension(req.get("org_id", ""))
        conn.sendall(json.dumps(result).encode())
    except Exception as exc:
        try:
            conn.sendall(json.dumps({"ok": False, "error": str(exc)}).encode())
        except Exception:
            pass
    finally:
        conn.close()


def _serve():
    SOCK_PATH.parent.mkdir(parents=True, exist_ok=True)
    try:
        SOCK_PATH.unlink()
    except FileNotFoundError:
        pass

    srv = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    srv.bind(str(SOCK_PATH))
    os.chmod(str(SOCK_PATH), 0o600)
    srv.listen(8)

    while True:
        conn, _ = srv.accept()
        threading.Thread(target=_handle_client, args=(conn,), daemon=True).start()


if __name__ == "__main__":
    threading.Thread(target=_nm_reader, daemon=True).start()
    _serve()
