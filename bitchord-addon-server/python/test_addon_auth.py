#!/usr/bin/env python3
"""BitChord Addon Auth Acceptance Test Suite.

Automated verification of Section 4 acceptance checklist:
1. /manifest.json is public, returns 200, declares bitchordAuth: true.
2. /search without BitChord headers returns HTTP 401 with WWW-Authenticate header.
3. /stream/:id without BitChord headers returns HTTP 401 with WWW-Authenticate header.
4. Forged/invalid headers are rejected with HTTP 401.
5. Media URLs: work without BitChord headers, validate HMAC signatures, and expire.
"""

import sys
import time
import json
import threading
import urllib.request
import urllib.error
from server import run_server, PORT, signed_media_url, MEDIA_SECRET

BASE_URL = f"http://127.0.0.1:{PORT}"

def log_test(name: str, passed: bool, detail: str = ""):
    mark = "✅ PASS" if passed else "❌ FAIL"
    print(f"[{mark}] {name} {detail}")
    if not passed:
        sys.exit(1)

def run_tests():
    print(f"🔬 Starting BitChord Addon Auth Acceptance Tests on {BASE_URL}...\n")

    # ── Test 1: Public Manifest
    try:
        req = urllib.request.Request(f"{BASE_URL}/manifest.json")
        with urllib.request.urlopen(req, timeout=5) as res:
            data = json.loads(res.read().decode())
            is_public = res.status == 200
            auth_flag = data.get("bitchordAuth") is True
            log_test("1. /manifest.json is public and declares bitchordAuth: true", is_public and auth_flag)
    except Exception as e:
        log_test("1. /manifest.json is public and declares bitchordAuth: true", False, str(e))

    # ── Test 2: Unauthenticated /search -> 401 missing
    try:
        req = urllib.request.Request(f"{BASE_URL}/search?q=test")
        urllib.request.urlopen(req, timeout=5)
        log_test("2. /search without headers returns 401", False, "Expected 401, got 200")
    except urllib.error.HTTPError as e:
        auth_header = e.headers.get("WWW-Authenticate", "")
        has_auth_challenge = 'BitChord realm="bitchord-addons"' in auth_header and 'error="missing"' in auth_header
        log_test("2. /search without headers returns 401 + BitChord WWW-Authenticate challenge", e.code == 401 and has_auth_challenge)

    # ── Test 3: Unauthenticated /stream -> 401 missing
    try:
        req = urllib.request.Request(f"{BASE_URL}/stream/confih_track_001")
        urllib.request.urlopen(req, timeout=5)
        log_test("3. /stream without headers returns 401", False, "Expected 401, got 200")
    except urllib.error.HTTPError as e:
        auth_header = e.headers.get("WWW-Authenticate", "")
        has_auth_challenge = 'BitChord realm="bitchord-addons"' in auth_header and 'error="missing"' in auth_header
        log_test("3. /stream without headers returns 401 + BitChord WWW-Authenticate challenge", e.code == 401 and has_auth_challenge)

    # ── Test 4: Forged headers -> 401 invalid_token / invalid_proof
    try:
        headers = {
            "X-BitChord-Token": "x.y.z",
            "X-BitChord-Proof": "v1.0.x"
        }
        req = urllib.request.Request(f"{BASE_URL}/search?q=test", headers=headers)
        urllib.request.urlopen(req, timeout=5)
        log_test("4. Forged headers are rejected with 401", False, "Expected 401, got 200")
    except urllib.error.HTTPError as e:
        auth_header = e.headers.get("WWW-Authenticate", "")
        has_auth_header = "BitChord" in auth_header and ("invalid_token" in auth_header or "invalid_proof" in auth_header)
        log_test("4. Forged headers are rejected with 401", e.code == 401 and has_auth_header)

    # ── Test 5: Media URLs work without headers
    media_url = signed_media_url(f"127.0.0.1:{PORT}", "confih_track_001", ttl_seconds=1800)
    try:
        req = urllib.request.Request(media_url)  # No auth headers attached!
        with urllib.request.urlopen(req, timeout=5) as res:
            media_ok = res.status == 200 and res.headers.get("Content-Type") == "audio/flac"
            log_test("5. Media URL works without BitChord headers", media_ok)
    except Exception as e:
        log_test("5. Media URL works without BitChord headers", False, str(e))

    # ── Test 6: Expired media URL is rejected (403)
    expired_media_url = signed_media_url(f"127.0.0.1:{PORT}", "confih_track_001", ttl_seconds=-10)
    try:
        req = urllib.request.Request(expired_media_url)
        urllib.request.urlopen(req, timeout=5)
        log_test("6. Expired media URL is rejected with 403", False, "Expected 403, got 200")
    except urllib.error.HTTPError as e:
        log_test("6. Expired media URL is rejected with 403", e.code == 403)

    # ── Test 7: Tampered media URL signature is rejected (403)
    tampered_media_url = media_url + "tampered"
    try:
        req = urllib.request.Request(tampered_media_url)
        urllib.request.urlopen(req, timeout=5)
        log_test("7. Tampered signature is rejected with 403", False, "Expected 403, got 200")
    except urllib.error.HTTPError as e:
        log_test("7. Tampered signature is rejected with 403", e.code == 403)

    print("\n🎉 ALL ACCEPTANCE CHECKS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    # Start server in background thread
    server_thread = threading.Thread(target=run_server, args=(PORT,), daemon=True)
    server_thread.start()
    time.sleep(1) # Give server time to bind port
    run_tests()
