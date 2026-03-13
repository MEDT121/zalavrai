// ════════════════════════════════════════════════════════════════════════════
//  ZALAVRAI — Service Worker  v11  ·  Production Ready
//  Cache offline + Background Sync + Periodic Sync
// ════════════════════════════════════════════════════════════════════════════

const CACHE   = 'zalavrai-v11';
const SYNC_TAG      = 'zalavrai-outbox';
const SYNC_TAG_PULL = 'zalavrai-pull';

// Ressources à mettre en cache au démarrage
const PRECACHE = [
  './index.html',
  './manifest.json',
];

// Domaines qui ne doivent JAMAIS passer par le cache
const BYPASS_HOSTS = [
  'script.google.com',
  'script.googleusercontent.com',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
  'cdnjs.cloudflare.com',
  'docs.google.com',       // gviz/tq requests
  'spreadsheets.google.com',
];

// ── Installation ─────────────────────────────────────────────────────────────
self.addEventListener('install', evt => {
  evt.waitUntil(
    caches.open(CACHE)
      .then(cache => cache.addAll(PRECACHE).catch(err => {
        console.warn('[SW] precache partial:', err.message);
      }))
      .then(() => self.skipWaiting())
  );
});

// ── Activation : nettoyage anciens caches ─────────────────────────────────────
self.addEventListener('activate', evt => {
  evt.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

// ── Fetch : Cache-First pour statique, Network-Only pour API ──────────────────
self.addEventListener('fetch', evt => {
  const url = new URL(evt.request.url);

  // Bypass total pour les API externes
  if (BYPASS_HOSTS.some(h => url.hostname.includes(h))) return;

  // Bypass pour toutes les requêtes POST/PUT (outbox)
  if (evt.request.method !== 'GET') return;

  // Cache-First avec fallback réseau
  evt.respondWith(
    caches.match(evt.request).then(cached => {
      if (cached) return cached;
      return fetch(evt.request).then(response => {
        if (
          response.ok &&
          (url.origin === self.location.origin || url.hostname === self.location.hostname)
        ) {
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

// ── Background Sync — déclenchée automatiquement quand le réseau revient ─────
// L'app enregistre 'zalavrai-outbox' quand il y a des items en attente
// Le SW déclenche cette sync dès que le réseau est disponible (même si l'app est fermée)
self.addEventListener('sync', evt => {
  if (evt.tag === SYNC_TAG) {
    evt.waitUntil(
      // Notifier tous les clients (onglets) de vider leur outbox
      self.clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then(clients => {
          if (clients.length > 0) {
            // App ouverte → lui dire de processer
            clients.forEach(client => client.postMessage({ type: 'BG_SYNC', tag: SYNC_TAG }));
          }
          // Si app fermée, on ne peut pas processer directement (pas d'accès à localStorage)
          // L'outbox sera vidée au prochain ouverture de l'app
        })
    );
  }

  if (evt.tag === SYNC_TAG_PULL) {
    evt.waitUntil(
      self.clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then(clients => {
          clients.forEach(client => client.postMessage({ type: 'BG_SYNC', tag: SYNC_TAG_PULL }));
        })
    );
  }
});

// ── Periodic Background Sync (Chrome 80+ sur Android) ───────────────────────
// Sync toutes les 30 minutes même si l'app est fermée
self.addEventListener('periodicsync', evt => {
  if (evt.tag === 'zalavrai-periodic') {
    evt.waitUntil(
      self.clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then(clients => {
          clients.forEach(client =>
            client.postMessage({ type: 'PERIODIC_SYNC' })
          );
        })
    );
  }
});

// ── Messages du client (app) vers le SW ──────────────────────────────────────
self.addEventListener('message', evt => {
  if (evt.data?.type === 'SKIP_WAITING') self.skipWaiting();
  if (evt.data?.type === 'CACHE_BUST') {
    caches.delete(CACHE).then(() => self.skipWaiting());
  }
});
