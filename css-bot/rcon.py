"""Source RCON protocol client (Valve Source engine).

Implements the Source RCON protocol for remote server administration:
https://developer.valvesoftware.com/wiki/Source_RCON_Protocol
"""

import socket
import struct
import select


# Packet types
SERVERDATA_AUTH = 3
SERVERDATA_AUTH_RESPONSE = 2
SERVERDATA_EXECCOMMAND = 2
SERVERDATA_RESPONSE_VALUE = 0


class RCONError(Exception):
    """Base RCON exception."""


class RCONAuthError(RCONError):
    """Authentication failed."""


class RCON:
    """Source RCON client with context-manager support."""

    def __init__(self, host, port, password, timeout=8):
        self.host = host
        self.port = int(port)
        self.password = password
        self.timeout = timeout
        self._sock = None
        self._req_id = 0

    def _next_id(self):
        self._req_id += 1
        return self._req_id

    def _packet(self, req_id, ptype, body):
        data = body.encode("utf-8", errors="replace") + b"\x00\x00"
        # size = id(4) + type(4) + body + 2 null bytes = 8 + len(data)
        return struct.pack("<iii", 8 + len(data), req_id, ptype) + data

    def _read_packet(self):
        """Read one full RCON packet, return (req_id, ptype, body)."""
        header = self._recv_exact(12)
        if len(header) < 12:
            raise RCONError("Connection closed by server")
        size, req_id, ptype = struct.unpack("<iii", header)
        body = self._recv_exact(size - 8) if size > 8 else b""
        # body ends with \x00\x00
        text = body[:-2].decode("utf-8", errors="replace") if len(body) >= 2 else ""
        return req_id, ptype, text

    def _recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            ready, _, _ = select.select([self._sock], [], [], self.timeout)
            if not ready:
                raise RCONError("Timed out waiting for server response")
            chunk = self._sock.recv(n - len(buf))
            if not chunk:
                break
            buf += chunk
        return buf

    def connect(self):
        """Open connection and authenticate."""
        self._sock = socket.create_connection(
            (self.host, self.port), timeout=self.timeout
        )
        auth_id = self._next_id()
        self._sock.sendall(self._packet(auth_id, SERVERDATA_AUTH, self.password))
        # Server replies with empty SERVERDATA_RESPONSE_VALUE then AUTH_RESPONSE
        req_id, ptype, _ = self._read_packet()  # empty response
        req_id, ptype, _ = self._read_packet()  # auth response
        if req_id == -1 or ptype != SERVERDATA_AUTH_RESPONSE:
            self.close()
            raise RCONAuthError("RCON authentication failed (wrong password?)")
        return self

    def command(self, cmd):
        """Execute a command, return full response text (multi-packet safe)."""
        if not self._sock:
            raise RCONError("Not connected")
        req_id = self._next_id()
        self._sock.sendall(self._packet(req_id, SERVERDATA_EXECCOMMAND, cmd))
        # Send a trailing empty packet as terminator marker
        term_id = self._next_id()
        self._sock.sendall(self._packet(term_id, SERVERDATA_EXECCOMMAND, ""))

        out = []
        while True:
            rid, ptype, text = self._read_packet()
            if rid == term_id:
                break
            if rid == req_id and ptype == SERVERDATA_RESPONSE_VALUE:
                out.append(text)
        return "".join(out)

    def close(self):
        if self._sock:
            try:
                self._sock.close()
            except OSError:
                pass
            self._sock = None

    def __enter__(self):
        return self.connect()

    def __exit__(self, *exc):
        self.close()


def parse_status(status_text):
    """Parse `status` output into a dict: hostname, map, players list.

    Player line format (CS:S v34):
        # userid "name" steamid connected ping loss state address
    e.g.: # 2 "Ali" STEAM_0:1:1234567 12:34 45 0 active 1.2.3.4:27005
    """
    import re
    info = {"hostname": "", "map": "", "players": []}
    #  userid   name        steamid  time   ping  loss  state  address
    player_re = re.compile(
        r'#\s*(\d+)\s+"(.+?)"\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+'
        r'(\S+)(?:\s+(\S+))?')
    for line in status_text.splitlines():
        line = line.strip()
        if line.startswith("hostname"):
            info["hostname"] = line.split(":", 1)[1].strip()
        elif line.startswith("map"):
            info["map"] = line.split(":", 1)[1].strip().split()[0]
        elif line.startswith("#"):
            m = player_re.search(line)
            if m:
                addr = m.group(8) or ""
                ip = addr.split(":")[0] if ":" in addr else addr
                info["players"].append({
                    "id": m.group(1),
                    "name": m.group(2),
                    "steamid": m.group(3),
                    "time": m.group(4),
                    "ping": m.group(5),
                    "ip": ip,
                })
            elif "userid" not in line.lower():
                # fallback for unusual formats: id + name at least
                parts = line.split()
                if len(parts) >= 3:
                    name = line.split('"')[1] if '"' in line else parts[2]
                    info["players"].append({
                        "id": parts[1], "name": name,
                        "steamid": "-", "time": "-", "ping": "?",
                        "ip": "",
                    })
    return info
