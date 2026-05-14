// ════════════════════════════════════════════════════════════════════════════
//  SchoolSafe — Service Worker  v2
//  Cache offline + Background Sync
// ════════════════════════════════════════════════════════════════════════════

const CACHE = 'schoolsafe-v4';

// Ressources à mettre en cache au démarrage
const PRECACHE = [
  './index.html',
  './manifest.json',
];

// Domaines qui ne passent jamais par le cache
const BYPASS_HOSTS = [
  'supabase.co',
  'script.google.com',
  'script.googleusercontent.com',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
  'cdnjs.cloudflare.com',
];

// ── Installation ──────────────────────────────────────────────────────────────
self.addEventListener('install', evt => {
  evt.waitUntil(
    caches.open(CACHE)
      .then(cache => cache.addAll(PRECACHE).catch(err => {
        console.warn('[SW] precache partial:', err.message);
      }))
      .then(() => self.skipWaiting())
  );
});

// ── Activation : supprime tous les anciens caches ────────────────────────────
self.addEventListener('activate', evt => {
  evt.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE).map(k => {
          console.log('[SW] suppression ancien cache:', k);
          return caches.delete(k);
        })
      ))
      .then(() => self.clients.claim())
  );
});

// ── Fetch : Network-First pour index.html, Cache-First pour le reste ──────────
self.addEventListener('fetch', evt => {
  const url = new URL(evt.request.url);

  // Bypass pour les API externes
  if (BYPASS_HOSTS.some(h => url.hostname.includes(h))) return;

  // Bypass pour POST/PATCH/DELETE
  if (evt.request.method !== 'GET') return;

  // Network-First pour index.html (toujours la version la plus récente)
  if (url.pathname.endsWith('/') || url.pathname.endsWith('index.html')) {
    evt.respondWith(
      fetch(evt.request)
        .then(response => {
          const clone = response.clone();
          caches.open(CACHE).then(cache => cache.put(evt.request, clone));
          return response;
        })
        .catch(() => caches.match('./index.html'))
    );
    return;
  }

  // Cache-First avec fallback réseau pour les autres ressources
  evt.respondWith(
    caches.match(evt.request).then(cached => {
      if (cached) return cached;
      return fetch(evt.request).then(response => {
        if (response.ok && url.origin === self.location.origin) {
          const clone = response.clone();
          caches.open(CACHE).then(cache => cache.put(evt.request, clone));
        }
        return response;
      }).catch(() => {
        if (evt.request.mode === 'navigate') {
          return caches.match('./index.html');
        }
      });
    })
  );
});

// ── Messages du client ────────────────────────────────────────────────────────
self.addEventListener('message', evt => {
  if (evt.data?.type === 'SKIP_WAITING') self.skipWaiting();
  if (evt.data?.type === 'CACHE_BUST') {
    caches.delete(CACHE).then(() => self.skipWaiting());
  }
});
