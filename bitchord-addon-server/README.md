# BitChord Add-on Server with Hardware Attestation Auth

Official, production-ready BitChord Add-on reference server implementation adhering to **BitChord Addon Auth Protocol Version 1** (as specified at [bitchord.kushagrasingh.in/docs#addon-auth](https://bitchord.kushagrasingh.in/docs#addon-auth)).

Includes complete, verified implementations for:
1. **Python 3.9+** (Zero-dependency standard library `server.py` + FastAPI `fastapi_server.py`)
2. **Node.js 20+** (Zero-dependency WebCrypto native `server.mjs`)
3. **Cloudflare Workers / Edge** (`worker.mjs`)

---

## 1. How It Works

1. **Manifest Declaration**:
   `GET /manifest.json` stays public and declares `"bitchordAuth": true`.
2. **Offline Hardware Verification**:
   The server downloads BitChord's public keys (`https://bitchord-auth.kushagrasingh.in/.well-known/jwks.json`) once an hour. On each request to `/search` or `/stream`, the verifier checks in <1ms:
   - `X-BitChord-Token`: Ed25519 JWT signed by BitChord Auth, issued to an official release-signed app on an untampered phone.
   - `X-BitChord-Proof`: Fresh ECDSA P-256 signature by the phone's hardware key (TEE/StrongBox) over the addon's hostname, timestamp, and token hash.
3. **Host Binding**:
   Bound to public host: `bitchord.confih.tech` (configurable via `BITCHORD_HOSTS`).
4. **Short-Lived Media URLs**:
   `/stream/:id` returns an HMAC-SHA256 signed URL to `/media/:id` valid for 15–30 minutes. The media route is public and does **not** require BitChord headers.
5. **Rollout Mode**:
   Supports `BITCHORD_AUTH_MODE=enforce` (default) or `BITCHORD_AUTH_MODE=log` for gradual deployment.

---

## 2. Directory Structure

```
bitchord-addon-server/
├── manifest.json                  # Official manifest with bitchordAuth: true & quality options
├── python/
│   ├── bitchord_addon_auth.py     # Verbatim official verifier (cryptography library)
│   ├── server.py                  # Production server (standard library HTTP, 0 extra deps)
│   ├── fastapi_server.py          # FastAPI / ASGI alternative
│   ├── test_addon_auth.py         # Automated acceptance test suite
│   ├── requirements.txt           # cryptography>=41.0.0
│   └── Dockerfile
├── node/
│   ├── bitchord-addon-auth.mjs    # Verbatim official verifier (0 deps, WebCrypto)
│   ├── server.mjs                 # Native Node.js HTTP server (0 deps)
│   ├── worker.mjs                 # Cloudflare Worker / Edge runtime handler
│   ├── test-addon-auth.mjs        # Automated acceptance test suite
│   ├── package.json
│   └── Dockerfile
└── README.md
```

---

## 3. Configuration & Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PORT` | `8080` | HTTP port to listen on. |
| `BITCHORD_HOSTS` | `bitchord.confih.tech` | Comma-separated public hostnames users reach the addon at (no scheme, no port). |
| `BITCHORD_AUTH_MODE` | `enforce` | `enforce` blocks unauthorized requests with 401; `log` logs refusals but allows traffic. |
| `MEDIA_SECRET` | `(random string)` | Secret key used to sign and verify short-lived HMAC media URLs. |
| `MEDIA_TTL_SECONDS` | `1800` | Expiration lifetime for media URLs (30 minutes; must be ≥ 300s). |

---

## 4. Running the Python Server

### Prerequisites
```bash
cd bitchord-addon-server/python
pip install -r requirements.txt
```

### Start the Server
```bash
python server.py
```

### Run Automated Acceptance Tests
```bash
python test_addon_auth.py
```

Output:
```
[✅ PASS] 1. /manifest.json is public and declares bitchordAuth: true
[✅ PASS] 2. /search without headers returns 401 + BitChord WWW-Authenticate challenge
[✅ PASS] 3. /stream without headers returns 401 + BitChord WWW-Authenticate challenge
[✅ PASS] 4. Forged headers are rejected with 401
[✅ PASS] 5. Media URL works without BitChord headers
[✅ PASS] 6. Expired media URL is rejected with 403
[✅ PASS] 7. Tampered signature is rejected with 403
🎉 ALL ACCEPTANCE CHECKS PASSED SUCCESSFULLY!
```

---

## 5. Running the Node.js Server

### Start the Server (Node 20+)
```bash
cd bitchord-addon-server/node
node server.mjs
```

### Run Automated Acceptance Tests
```bash
node test-addon-auth.mjs
```

### Deploy to Cloudflare Workers
```bash
cd bitchord-addon-server/node
npx wrangler deploy worker.mjs --name bitchord-addon
```

---

## 6. Official Acceptance Checks (cURL)

Replace `https://bitchord.confih.tech` with your server URL:

```bash
# 1. Manifest is public and declares bitchordAuth
curl -s https://bitchord.confih.tech/manifest.json | grep -o '"bitchordAuth": *[^,}]*'
# "bitchordAuth": true

# 2. Requests without BitChord headers are refused with WWW-Authenticate challenge
curl -si 'https://bitchord.confih.tech/search?q=test' | head -5
# HTTP/1.1 401 Unauthorized
# www-authenticate: BitChord realm="bitchord-addons", error="missing", ...

# 3. Stream route is refused without headers
curl -si 'https://bitchord.confih.tech/stream/confih_track_001' | head -1
# HTTP/1.1 401 Unauthorized

# 4. Forged headers are rejected
curl -si -H 'X-BitChord-Token: x.y.z' -H 'X-BitChord-Proof: v1.0.x' 'https://bitchord.confih.tech/search?q=test' | head -1
# HTTP/1.1 401 Unauthorized

# 5. Media URLs work without headers and expire after TTL
curl -si 'https://bitchord.confih.tech/media/confih_track_001?exp=...&sig=...' | head -5
# HTTP/1.1 200 OK
# content-type: audio/flac
```

---

## 7. Adding the Add-on in AuraBeat / BitChord

1. Open **AuraBeat** (or official BitChord).
2. Go to **Settings → Sources → Add an Addon**.
3. Enter `https://bitchord.confih.tech`.
4. The addon will install without the *"Outdated addon"* warning and verify all search & playback streams!
