#!/usr/bin/env python3
"""BitChord Add-on FastAPI Server.

FastAPI implementation with asynchronous endpoints and BitChord Addon Auth.
Run with: uvicorn fastapi_server:app --host 0.0.0.0 --port 8080
"""

import os
import time
import hmac
import hashlib
import urllib.parse
from typing import Optional, List, Dict, Any

from fastapi import FastAPI, Request, Response, Depends, HTTPException, Query
from fastapi.responses import JSONResponse, Response as RawResponse
from fastapi.middleware.cors import CORSMiddleware
from starlette.concurrency import run_in_threadpool

from bitchord_addon_auth import BitChordAuth, TOKEN_HEADER, PROOF_HEADER

# ── Configuration
HOSTS_CONFIG = os.environ.get("BITCHORD_HOSTS", "bitchord.confih.tech,localhost,127.0.0.1")
BITCHORD_HOSTS = [h.strip() for h in HOSTS_CONFIG.split(",") if h.strip()]
AUTH_MODE = os.environ.get("BITCHORD_AUTH_MODE", "enforce").lower()
MEDIA_SECRET = os.environ.get("MEDIA_SECRET", "bitchord_confih_master_secret_key_9876543210")
MEDIA_TTL_SECONDS = int(os.environ.get("MEDIA_TTL_SECONDS", "1800"))

MANIFEST = {
    "id": "app.bitchord.confih",
    "name": "BitChord Confih Studio",
    "version": "2.0.0",
    "resources": ["search", "stream"],
    "bitchordAuth": True,
    "allowDownloads": True,
    "quality": [
        {"value": "max", "label": "Hi-Res & Dolby Atmos (24-bit / 192 kHz FLAC)"},
        {"value": "lossless", "label": "CD Lossless (16-bit / 44.1 kHz FLAC)"},
        {"value": "high", "label": "High Fidelity (320 kbps AAC / MP3)"},
        {"value": "low", "label": "Data Saver (96–128 kbps)"}
    ]
}

# ── Verifier instance (Module scope)
bitchord = BitChordAuth(hosts=BITCHORD_HOSTS)

app = FastAPI(title="BitChord Confih Add-on", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Denied(Exception):
    def __init__(self, result):
        self.result = result

@app.exception_handler(Denied)
async def denied_handler(_, exc: Denied):
    return Response(
        content=exc.result.body,
        status_code=exc.result.status,
        headers=exc.result.headers
    )

async def require_bitchord(request: Request):
    """Dependency that verifies BitChord hardware proof on protected routes."""
    # verify_headers performs network fetch of JWKS when cache expires, run in threadpool
    result = await run_in_threadpool(bitchord.verify_headers, request.headers)
    if not result.ok:
        if AUTH_MODE == "log":
            print(f"[BITCHORD-AUTH LOG MODE]: Rejected - {result.error} ({result.message})")
            return {"sub": "log-mode-user"}
        raise Denied(result)
    return result.claims

# ── Task 1: Public Manifest Route
@app.get("/manifest.json")
def get_manifest():
    return MANIFEST

# ── Task 4: Short-Lived Signed Media Route (Public to player)
@app.get("/media/{track_id}")
def get_media(track_id: str, exp: str = Query(...), sig: str = Query(...)):
    if not exp.isdigit() or int(exp) < time.time():
        raise HTTPException(status_code=403, detail="Expired media URL")
    
    msg = f"{track_id}.{exp}".encode("utf-8")
    want = hmac.new(MEDIA_SECRET.encode("utf-8"), msg, hashlib.sha256).digest()
    try:
        sig_raw = __import__("base64").urlsafe_b64decode(sig + "=" * (-len(sig) % 4))
        if not hmac.compare_digest(want, sig_raw):
            raise HTTPException(status_code=403, detail="Invalid media signature")
    except Exception:
        raise HTTPException(status_code=403, detail="Malformed signature")

    audio_bytes = b"OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00BitChordConfihHiResAudioStreamData..."
    return RawResponse(content=audio_bytes, media_type="audio/flac")

# ── Task 3: Protected Routes
@app.get("/search")
def search(q: str = Query(""), quality: str = Query("max"), claims=Depends(require_bitchord)):
    return [
        {
            "id": "confih_track_001",
            "title": "Starboy (Studio Master Direct)",
            "artist": "The Weeknd ft. Daft Punk",
            "album": "Confih Hi-Res Vault",
            "duration": 230,
            "artwork": "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80",
            "format": "FLAC",
            "quality": quality,
            "isDolbyAtmos": False,
        }
    ]

@app.get("/stream/{track_id}")
def stream(request: Request, track_id: str, quality: str = Query("max"), claims=Depends(require_bitchord)):
    host = request.headers.get("host", "bitchord.confih.tech")
    exp = int(time.time()) + MEDIA_TTL_SECONDS
    msg = f"{track_id}.{exp}".encode("utf-8")
    sig = hmac.new(MEDIA_SECRET.encode("utf-8"), msg, hashlib.sha256).digest()
    sig_b64 = urllib.parse.quote_plus(__import__("base64").urlsafe_b64encode(sig).rstrip(b"=").decode("ascii"))
    scheme = "https" if "localhost" not in host else "http"
    media_url = f"{scheme}://{host}/media/{track_id}?exp={exp}&sig={sig_b64}"

    return {
        "url": media_url,
        "format": "FLAC",
        "sampleRate": 192000,
        "bitDepth": 24,
        "quality": quality,
        "expiresIn": MEDIA_TTL_SECONDS
    }
