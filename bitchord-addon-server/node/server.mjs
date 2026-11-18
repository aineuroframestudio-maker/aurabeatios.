// BitChord Add-on Reference Server (Node.js 20+)
//
// Zero external dependencies. Uses only standard Node.js APIs & WebCrypto.
// Fully implements BitChord Addon Auth protocol version 1.

import http from 'node:http';
import crypto from 'node:crypto';
import { URL } from 'node:url';
import { createBitChordAuth, TOKEN_HEADER, PROOF_HEADER } from './bitchord-addon-auth.mjs';

// ── Configuration from Environment
const PORT = Number(process.env.PORT || 8080);
const HOSTS_CONFIG = process.env.BITCHORD_HOSTS || 'bitchord.confih.tech,localhost,127.0.0.1';
const BITCHORD_HOSTS = HOSTS_CONFIG.split(',').map((h) => h.trim()).filter(Boolean);
const AUTH_MODE = (process.env.BITCHORD_AUTH_MODE || 'enforce').toLowerCase(); // enforce | log
const MEDIA_SECRET = process.env.MEDIA_SECRET || 'bitchord_confih_master_secret_key_9876543210';
const MEDIA_TTL_SECONDS = Number(process.env.MEDIA_TTL_SECONDS || 1800); // 30 minutes

// ── Task 1: Manifest Definition (Public)
const MANIFEST = {
  id: 'app.bitchord.confih',
  name: 'BitChord Confih Studio',
  version: '2.0.0',
  description: 'Official BitChord Confih Hi-Res Master Streaming & Discovery Add-on',
  resources: ['search', 'stream'],
  bitchordAuth: true,
  allowDownloads: true,
  checkValidLossless: false,
  quality: [
    { value: 'max', label: 'Hi-Res & Dolby Atmos (24-bit / 192 kHz FLAC)' },
    { value: 'lossless', label: 'CD Lossless (16-bit / 44.1 kHz FLAC)' },
    { value: 'high', label: 'High Fidelity (320 kbps AAC / MP3)' },
    { value: 'low', label: 'Data Saver (96–128 kbps)' },
  ],
  settings: [
    {
      key: 'atmos',
      title: 'Dolby Atmos Spatial Audio',
      type: 'select',
      options: ['always', 'headphones', 'off'],
      default: 'always',
    },
  ],
};

// ── Task 2 & 3: Single verifier instance at module scope
const bitchord = createBitChordAuth({ hosts: BITCHORD_HOSTS });

// ── Task 4: Short-Lived Signed Media Helpers
export function signedMediaUrl(hostHeader, trackId, ttlSeconds = MEDIA_TTL_SECONDS) {
  const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
  const sig = crypto.createHmac('sha256', MEDIA_SECRET).update(`${trackId}.${exp}`).digest('base64url');
  const scheme = hostHeader.includes('localhost') || hostHeader.includes('127.0.0.1') ? 'http' : 'https';
  return `${scheme}://${hostHeader}/media/${encodeURIComponent(trackId)}?exp=${exp}&sig=${sig}`;
}

export function mediaAllowed(trackId, exp, sig) {
  if (!/^\d+$/.test(String(exp)) || Number(exp) < Date.now() / 1000) return false;
  const want = crypto.createHmac('sha256', MEDIA_SECRET).update(`${trackId}.${exp}`).digest();
  const got = Buffer.from(String(sig || ''), 'base64url');
  return got.length === want.length && crypto.timingSafeEqual(got, want);
}

// ── Sample Catalog Database
const TRACKS_CATALOG = [
  {
    id: 'confih_track_001',
    title: 'Starboy (Studio Master Direct)',
    artist: 'The Weeknd ft. Daft Punk',
    album: 'Confih Hi-Res Vault',
    duration: 230,
    artwork: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
    format: 'FLAC',
    sampleRate: 192000,
    bitDepth: 24,
    bitrate: 9216,
    isDolbyAtmos: false,
  },
  {
    id: 'confih_track_002',
    title: 'Blinding Lights (Dolby Atmos Spatial Audio)',
    artist: 'The Weeknd',
    album: 'BitChord Studio Masters',
    duration: 200,
    artwork: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
    format: 'E-AC-3',
    sampleRate: 48000,
    bitDepth: 16,
    bitrate: 768,
    isDolbyAtmos: true,
  },
  {
    id: 'confih_track_003',
    title: 'Midnight City (Pure Lossless MQA)',
    artist: 'M83',
    album: "Hurry Up, We're Dreaming",
    duration: 244,
    artwork: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
    format: 'FLAC',
    sampleRate: 96000,
    bitDepth: 24,
    bitrate: 4608,
    isDolbyAtmos: false,
  },
];

// Helper to write JSON responses
function sendJson(res, status, data, extraHeaders = {}) {
  const body = JSON.stringify(data);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': Buffer.byteLength(body),
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, HEAD, OPTIONS',
    'access-control-allow-headers': `${TOKEN_HEADER}, ${PROOF_HEADER}, Range, Content-Type`,
    ...extraHeaders,
  });
  res.end(body);
}

// ── HTTP Request Handler
const server = http.createServer(async (req, res) => {
  const host = req.headers.host || `localhost:${PORT}`;
  const url = new URL(req.url, `http://${host}`);
  const pathname = url.pathname;

  // Handle CORS Pre-flight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET, HEAD, OPTIONS',
      'access-control-allow-headers': `${TOKEN_HEADER}, ${PROOF_HEADER}, Range, Content-Type`,
    });
    return res.end();
  }

  // ── 1. Manifest: Always PUBLIC (Task 1)
  if (pathname === '/manifest.json' || pathname.endsWith('/manifest.json')) {
    return sendJson(res, 200, MANIFEST);
  }

  // ── 2. Media Route: Public, Signed Short-Lived URLs (Task 4)
  // Does NOT require X-BitChord-* headers.
  if (pathname.startsWith('/media/')) {
    const trackId = decodeURIComponent(pathname.slice('/media/'.length));
    const exp = url.searchParams.get('exp');
    const sig = url.searchParams.get('sig');

    if (!mediaAllowed(trackId, exp, sig)) {
      return sendJson(res, 403, {
        error: 'media_forbidden',
        message: 'Media link has expired or signature is invalid.',
      });
    }

    const audioChunk = Buffer.from('OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00BitChordConfihHiResAudioStreamData...');
    res.writeHead(200, {
      'content-type': 'audio/flac',
      'content-length': audioChunk.length,
      'accept-ranges': 'bytes',
      'access-control-allow-origin': '*',
      'cache-control': 'no-cache',
    });
    return res.end(audioChunk);
  }

  // ── 3. Authenticate BitChord requests (Task 2, 3 & 5)
  const authResult = await bitchord.verifyRequest(req);
  if (!authResult.ok) {
    if (AUTH_MODE === 'log') {
      console.warn(`[BITCHORD-AUTH LOG MODE]: would refuse: ${authResult.error} (${authResult.message})`);
    } else {
      // Send rejection with official helper
      const rejection = bitchord.rejection(authResult);
      res.writeHead(rejection.status, {
        ...rejection.headers,
        'access-control-allow-origin': '*',
      });
      return res.end(rejection.body);
    }
  }

  // ── 4. Protected /search Endpoint
  if (pathname === '/search') {
    const q = (url.searchParams.get('q') || '').toLowerCase();
    const quality = url.searchParams.get('quality') || 'max';

    const results = TRACKS_CATALOG.filter(
      (t) => !q || t.title.toLowerCase().includes(q) || t.artist.toLowerCase().includes(q) || t.album.toLowerCase().includes(q)
    ).map((t) => ({
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: t.duration,
      artwork: t.artwork,
      quality,
      format: t.format,
      isDolbyAtmos: t.isDolbyAtmos,
    }));

    return sendJson(res, 200, results);
  }

  // ── 5. Protected /stream/:id Endpoint
  if (pathname.startsWith('/stream/')) {
    const trackId = decodeURIComponent(pathname.slice('/stream/'.length));
    const quality = url.searchParams.get('quality') || 'max';

    const matched = TRACKS_CATALOG.find((t) => t.id === trackId);
    if (!matched) {
      return sendJson(res, 404, { error: 'track_not_found', message: `Track ${trackId} not found` });
    }

    // Generate short-lived signed URL (Task 4)
    const mediaUrl = signedMediaUrl(host, trackId, MEDIA_TTL_SECONDS);

    return sendJson(res, 200, {
      url: mediaUrl,
      format: matched.format,
      quality,
      sampleRate: matched.sampleRate,
      bitDepth: matched.bitDepth,
      bitrate: matched.bitrate,
      isDolbyAtmos: matched.isDolbyAtmos,
      expiresIn: MEDIA_TTL_SECONDS,
    });
  }

  // 404 Not Found
  sendJson(res, 404, { error: 'not_found', path: pathname });
});

export function startServer(port = PORT) {
  server.listen(port, () => {
    console.log(`🎵 BitChord Add-on Server (Node.js) running on http://localhost:${port}`);
    console.log(`   Configured Hosts: ${JSON.stringify(BITCHORD_HOSTS)}`);
    console.log(`   Auth Mode: ${AUTH_MODE.toUpperCase()}`);
    console.log(`   Manifest: http://localhost:${port}/manifest.json (PUBLIC)`);
  });
}

if (process.argv[1] && process.argv[1].endsWith('server.mjs')) {
  startServer(PORT);
}
