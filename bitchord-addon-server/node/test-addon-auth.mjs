// Automated Acceptance Tests for BitChord Addon Auth (Node.js)

import { startServer, signedMediaUrl } from './server.mjs';

const PORT = 8081;
const BASE_URL = `http://127.0.0.1:${PORT}`;

function logTest(name, passed, detail = '') {
  const mark = passed ? '✅ PASS' : '❌ FAIL';
  console.log(`[${mark}] ${name} ${detail}`);
  if (!passed) {
    process.exit(1);
  }
}

async function runTests() {
  process.env.PORT = String(PORT);
  process.env.BITCHORD_HOSTS = 'bitchord.confih.tech,localhost,127.0.0.1';
  startServer(PORT);
  await new Promise((resolve) => setTimeout(resolve, 500));

  console.log(`\n🔬 Running Node.js BitChord Addon Auth Acceptance Tests on ${BASE_URL}...\n`);

  // ── Test 1: Public Manifest
  try {
    const res = await fetch(`${BASE_URL}/manifest.json`);
    const data = await res.json();
    logTest('1. /manifest.json is public and declares bitchordAuth: true', res.status === 200 && data.bitchordAuth === true);
  } catch (err) {
    logTest('1. /manifest.json is public and declares bitchordAuth: true', false, err.message);
  }

  // ── Test 2: Unauthenticated /search -> 401 missing
  try {
    const res = await fetch(`${BASE_URL}/search?q=test`);
    const authHeader = res.headers.get('www-authenticate') || '';
    const hasChallenge = authHeader.includes('BitChord realm="bitchord-addons"') && authHeader.includes('error="missing"');
    logTest('2. /search without headers returns 401 + BitChord WWW-Authenticate challenge', res.status === 401 && hasChallenge);
  } catch (err) {
    logTest('2. /search without headers returns 401', false, err.message);
  }

  // ── Test 3: Unauthenticated /stream -> 401 missing
  try {
    const res = await fetch(`${BASE_URL}/stream/confih_track_001`);
    const authHeader = res.headers.get('www-authenticate') || '';
    const hasChallenge = authHeader.includes('BitChord realm="bitchord-addons"') && authHeader.includes('error="missing"');
    logTest('3. /stream without headers returns 401 + BitChord WWW-Authenticate challenge', res.status === 401 && hasChallenge);
  } catch (err) {
    logTest('3. /stream without headers returns 401', false, err.message);
  }

  // ── Test 4: Forged headers -> 401
  try {
    const res = await fetch(`${BASE_URL}/search?q=test`, {
      headers: {
        'x-bitchord-token': 'x.y.z',
        'x-bitchord-proof': 'v1.0.x',
      },
    });
    const authHeader = res.headers.get('www-authenticate') || '';
    const isRejected = res.status === 401 && authHeader.includes('BitChord') && (authHeader.includes('invalid_token') || authHeader.includes('invalid_proof'));
    logTest('4. Forged headers are rejected with 401', isRejected);
  } catch (err) {
    logTest('4. Forged headers are rejected with 401', false, err.message);
  }

  // ── Test 5: Media URLs work without headers
  const mediaUrl = signedMediaUrl(`127.0.0.1:${PORT}`, 'confih_track_001', 1800);
  try {
    const res = await fetch(mediaUrl); // No auth headers!
    const mediaOk = res.status === 200 && res.headers.get('content-type') === 'audio/flac';
    logTest('5. Media URL works without BitChord headers', mediaOk);
  } catch (err) {
    logTest('5. Media URL works without BitChord headers', false, err.message);
  }

  // ── Test 6: Expired media URL is rejected (403)
  const expiredUrl = signedMediaUrl(`127.0.0.1:${PORT}`, 'confih_track_001', -10);
  try {
    const res = await fetch(expiredUrl);
    logTest('6. Expired media URL is rejected with 403', res.status === 403);
  } catch (err) {
    logTest('6. Expired media URL is rejected with 403', false, err.message);
  }

  // ── Test 7: Tampered media signature is rejected (403)
  const tamperedUrl = `${mediaUrl}tampered`;
  try {
    const res = await fetch(tamperedUrl);
    logTest('7. Tampered signature is rejected with 403', res.status === 403);
  } catch (err) {
    logTest('7. Tampered signature is rejected with 403', false, err.message);
  }

  console.log('\n🎉 ALL NODE.JS ACCEPTANCE CHECKS PASSED SUCCESSFULLY!\n');
  process.exit(0);
}

runTests();
