// ponytail: network-first for pages, cache-first for the hashed assets they name.
// Bump CACHE to evict everything a previous version stored.
const CACHE = "wordroot-v4";
// Wiktionary pages already looked up, kept across releases so they open offline. ponytail: newest 600, then oldest go.
const WORDS = "wordroot-words";
const WORDS_MAX = 600;
const FILES = ["/", "/index.html","/privacy.html", "/manifest.webmanifest"];

self.addEventListener("install", e => {
  // A single missing file fails the whole addAll, so tolerate misses.
  e.waitUntil(caches.open(CACHE)
    .then(c => Promise.all(FILES.map(f => c.add(f).catch(() => {}))))
    .then(() => self.skipWaiting()));
});

self.addEventListener("activate", e => {
  e.waitUntil(caches.keys()
    .then(ks => Promise.all(ks.filter(k => k !== CACHE && k !== WORDS).map(k => caches.delete(k))))
    .then(() => self.clients.claim()));
});

const save = (req, res) => {
  if (res.ok && res.type === "basic") {
    const copy = res.clone();
    caches.open(CACHE).then(c => c.put(req, copy));
  }
  return res;
};

// A word's definitions and its page wikitext: the two requests a lookup needs to draw an entry.
const isWordPage = url => url.hostname.endsWith(".wiktionary.org") &&
  (url.pathname.startsWith("/api/rest_v1/page/definition/") || (url.pathname === "/w/api.php" && url.searchParams.get("action") === "parse"));

self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  const url = new URL(e.request.url);
  // Looked-up words: network first, the last copy when offline.
  if (isWordPage(url)) {
    e.respondWith(fetch(e.request).then(res => {
      if (res.ok) {
        const copy = res.clone();
        caches.open(WORDS).then(c => c.put(e.request, copy).then(() => c.keys())
          .then(ks => Promise.all(ks.slice(0, Math.max(0, ks.length - WORDS_MAX)).map(k => c.delete(k)))));
      }
      return res;
    }).catch(() => caches.open(WORDS).then(c => c.match(e.request)).then(hit => hit || Response.error())));
    return;
  }
  // Other GETs: same origin only; the rest of the APIs stay network-only.
  if (url.origin !== location.origin) return;

  // HTML must never come from cache first: it names the hashed bundles, so one
  // stale page pins a whole stale build and the site stops shipping updates to
  // anyone who has already visited. Network first, cache only as an offline fallback.
  if (e.request.mode === "navigate") {
    e.respondWith(
      fetch(e.request)
        .then(res => save(e.request, res))
        .catch(() => caches.match(e.request, { ignoreSearch: true })
          .then(hit => hit || caches.match(FILES[0])))
    );
    return;
  }

  // Everything else is content-hashed, so a cache hit is always the right file.
  e.respondWith(
    caches.match(e.request, { ignoreSearch: true }).then(hit => hit ||
      fetch(e.request).then(res => save(e.request, res)))
  );
});
