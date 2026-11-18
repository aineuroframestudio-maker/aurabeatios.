#!/usr/bin/env python3
"""BitChord Add-on Reference Server (Python).

Fully implements the BitChord Add-on Protocol v1 with BitChord Addon Auth.
- Public /manifest.json endpoint
- Protected /search and /stream endpoints guarded by BitChordAuth
- Short-lived HMAC-signed /media URLs (15-30 min expiry)
- Rollout modes: BITCHORD_AUTH_MODE=enforce (default) or log

Requires: pip install cryptography
Runs on Python 3.9+ using standard library HTTP server (or easily adapted to FastAPI/Flask).
"""

import os
import sys
import json
import time
import hmac
import hashlib
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from typing import Dict, Any, Optional

from bitchord_addon_auth import BitChordAuth, TOKEN_HEADER, PROOF_HEADER

# ── Configuration from Environment
PORT = int(os.environ.get("PORT", "8080"))
HOSTS_CONFIG = os.environ.get("BITCHORD_HOSTS", "bitchord.confih.tech,localhost,127.0.0.1")
BITCHORD_HOSTS = [h.strip() for h in HOSTS_CONFIG.split(",") if h.strip()]
AUTH_MODE = os.environ.get("BITCHORD_AUTH_MODE", "enforce").lower()  # enforce | log
MEDIA_SECRET = os.environ.get("MEDIA_SECRET", "bitchord_confih_master_secret_key_9876543210")
MEDIA_TTL_SECONDS = int(os.environ.get("MEDIA_TTL_SECONDS", "1800"))  # 30 minutes

# ── Manifest Definition (Task 1)
MANIFEST = {
    "id": "app.bitchord.confih",
    "name": "BitChord Confih Studio",
    "version": "2.0.0",
    "description": "Official BitChord Confih Hi-Res Master Streaming & Discovery Add-on",
    "resources": ["search", "stream"],
    "bitchordAuth": True,
    "allowDownloads": True,
    "checkValidLossless": False,
    "quality": [
        {"value": "max", "label": "Hi-Res & Dolby Atmos (24-bit / 192 kHz FLAC)"},
        {"value": "lossless", "label": "CD Lossless (16-bit / 44.1 kHz FLAC)"},
        {"value": "high", "label": "High Fidelity (320 kbps AAC / MP3)"},
        {"value": "low", "label": "Data Saver (96–128 kbps)"}
    ],
    "settings": [
        {
            "key": "atmos",
            "title": "Dolby Atmos Spatial Audio",
            "type": "select",
            "options": ["always", "headphones", "off"],
            "default": "always"
        }
    ]
}

# ── Verifier Instance (Task 2 & 3: Single instance at module scope)
bitchord = BitChordAuth(hosts=BITCHORD_HOSTS)


# ── Short-Lived Signed Media Helpers (Task 4)
def signed_media_url(host_header: str, track_id: str, ttl_seconds: int = MEDIA_TTL_SECONDS) -> str:
    """Creates an HMAC-SHA256 signed URL expiring in ttl_seconds."""
    exp = int(time.time()) + ttl_seconds
    msg = f"{track_id}.{exp}".encode("utf-8")
    sig = hmac.new(MEDIA_SECRET.encode("utf-8"), msg, hashlib.sha256).digest()
    sig_b64 = urllib.parse.quote_plus(
        __import__("base64").urlsafe_b64encode(sig).rstrip(b"=").decode("ascii")
    )
    scheme = "https" if "localhost" not in host_header and "127.0.0.1" not in host_header else "http"
    return f"{scheme}://{host_header}/media/{urllib.parse.quote(track_id)}?exp={exp}&sig={sig_b64}"


def media_allowed(track_id: str, exp_str: Optional[str], sig_str: Optional[str]) -> bool:
    """Verifies that the media URL signature is valid and has not expired."""
    if not exp_str or not sig_str or not exp_str.isdigit():
        return False
    exp = int(exp_str)
    if exp < time.time():
        return False  # Expired
    msg = f"{track_id}.{exp}".encode("utf-8")
    want = hmac.new(MEDIA_SECRET.encode("utf-8"), msg, hashlib.sha256).digest()
    try:
        # Base64url decode with padding restoration
        sig_raw = __import__("base64").urlsafe_b64decode(sig_str + "=" * (-len(sig_str) % 4))
        return hmac.compare_digest(want, sig_raw)
    except Exception:
        return False


# ── Sample Catalog Database
TRACKS_CATALOG = [
    {
        "id": "confih_track_001",
        "title": "Starboy (Studio Master Direct)",
        "artist": "The Weeknd ft. Daft Punk",
        "album": "Confih Hi-Res Vault",
        "duration": 230,
        "artwork": "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80",
        "format": "FLAC",
        "sampleRate": 192000,
        "bitDepth": 24,
        "bitrate": 9216,
        "isDolbyAtmos": False,
    },
    {
        "id": "confih_track_002",
        "title": "Blinding Lights (Dolby Atmos Spatial Audio)",
        "artist": "The Weeknd",
        "album": "BitChord Studio Masters",
        "duration": 200,
        "artwork": "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80",
        "format": "E-AC-3",
        "sampleRate": 48000,
        "bitDepth": 16,
        "bitrate": 768,
        "isDolbyAtmos": True,
    },
    {
        "id": "confih_track_003",
        "title": "Midnight City (Pure Lossless MQA)",
        "artist": "M83",
        "album": "Hurry Up, We're Dreaming",
        "duration": 244,
        "artwork": "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80",
        "format": "FLAC",
        "sampleRate": 96000,
        "bitDepth": 24,
        "bitrate": 4608,
        "isDolbyAtmos": False,
    }
]


class BitChordAddonHandler(BaseHTTPRequestHandler):
    """HTTP Request Handler for BitChord Add-on Service."""

    def _send_json(self, status: int, data: Any, extra_headers: Optional[Dict[str, str]] = None):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", f"{TOKEN_HEADER}, {PROOF_HEADER}, Range, Content-Type")
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", f"{TOKEN_HEADER}, {PROOF_HEADER}, Range, Content-Type")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        # ── 1. Manifest is always PUBLIC (Task 1)
        if path.endswith("/manifest.json") or path == "/manifest.json":
            self._send_json(200, MANIFEST)
            return

        # ── 2. Media route: Public, signed short-lived URLs (Task 4)
        # Does NOT require BitChord headers.
        if path.startswith("/media/"):
            track_id = path[len("/media/"):]
            exp = query.get("exp", [None])[0]
            sig = query.get("sig", [None])[0]

            if not media_allowed(track_id, exp, sig):
                self._send_json(403, {
                    "error": "media_forbidden",
                    "message": "Media link has expired or signature is invalid."
                })
                return

            # Serve audio chunk/stream simulation
            content = b"OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00BitChordConfihHiResAudioStreamData..."
            self.send_response(200)
            self.send_header("Content-Type", "audio/flac")
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(content)
            return

        # ── 3. Authenticate BitChord requests (Task 2, 3 & 5)
        auth_result = bitchord.verify_headers(self.headers)
        if not auth_result.ok:
            if AUTH_MODE == "log":
                sys.stderr.write(f"[BITCHORD-AUTH WOULD REFUSE]: {auth_result.error} - {auth_result.message}\n")
            else:
                # Task 3: Always send rejections with the helper headers and body
                self.send_response(auth_result.status)
                for k, v in auth_result.headers.items():
                    self.send_header(k, v)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(auth_result.body.encode("utf-8"))
                return

        # ── 4. Protected /search Endpoint
        if path == "/search":
            q = query.get("q", [""])[0].lower()
            quality = query.get("quality", ["max"])[0]

            results = []
            for t in TRACKS_CATALOG:
                if not q or q in t["title"].lower() or q in t["artist"].lower() or q in t["album"].lower():
                    results.append({
                        "id": t["id"],
                        "title": t["title"],
                        "artist": t["artist"],
                        "album": t["album"],
                        "duration": t["duration"],
                        "artwork": t["artwork"],
                        "quality": quality,
                        "format": t["format"],
                        "isDolbyAtmos": t["isDolbyAtmos"],
                    })

            self._send_json(200, results)
            return

        # ── 5. Protected /stream Endpoint
        if path.startswith("/stream/"):
            track_id = path[len("/stream/"):]
            quality = query.get("quality", ["max"])[0]
            host_header = self.headers.get("Host", f"localhost:{PORT}")

            matched = next((t for t in TRACKS_CATALOG if t["id"] == track_id), None)
            if not matched:
                self._send_json(404, {"error": "track_not_found", "message": f"Track {track_id} not in catalog"})
                return

            # Task 4: Short-lived signed URL
            media_url = signed_media_url(host_header, track_id, ttl_seconds=MEDIA_TTL_SECONDS)

            self._send_json(200, {
                "url": media_url,
                "format": matched["format"],
                "quality": quality,
                "sampleRate": matched["sampleRate"],
                "bitDepth": matched["bitDepth"],
                "bitrate": matched["bitrate"],
                "isDolbyAtmos": matched["isDolbyAtmos"],
                "expiresIn": MEDIA_TTL_SECONDS
            })
            return

        # ── 404 Not Found
        self._send_json(404, {"error": "not_found", "path": path})


def run_server(port: int = PORT):
    server_address = ("0.0.0.0", port)
    httpd = ThreadingHTTPServer(server_address, BitChordAddonHandler)
    print(f"🎵 BitChord Add-on Server (Python) running on http://0.0.0.0:{port}")
    print(f"   Configured Hosts: {BITCHORD_HOSTS}")
    print(f"   Auth Mode: {AUTH_MODE.upper()}")
    print(f"   Manifest: http://0.0.0.0:{port}/manifest.json (PUBLIC)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()


if __name__ == "__main__":
    run_server(PORT)
