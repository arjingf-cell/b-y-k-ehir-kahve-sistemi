// Service Worker for Kıraathane Finans PWA
const CACHE_NAME = 'kiraathane-finans-v8';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  // 1. Yalnızca GET isteklerini işle (POST, PUT, DELETE vb. doğrudan tarayıcı düzeyine bırakılsın)
  if (event.request.method !== 'GET') {
    return;
  }

  // 2. Harici origin isteklerini (Supabase, Google Fonts, CDN vb.) doğrudan tarayıcı düzeyine bırak
  const requestUrl = new URL(event.request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  // 3. İstek açıkça yönlendirme modu (manual) içeriyorsa service worker devreye girmesin, tarayıcıya bırakılsın
  if (event.request.redirect === 'manual') {
    return;
  }

  // 4. Network first with cache fallback & Safari redirection koruması
  event.respondWith(
    (async () => {
      try {
        const response = await fetch(event.request);

        // event.respondWith() içine aktarılan yanıt nesnesinin yönlendirme barındırıp barındırmadığını denetle
        // Safari/WebKit "Response served by service worker has redirections" hatasını önle
        if (response && (response.redirected || (response.status >= 300 && response.status < 400))) {
          // Eğer yanıt yönlendirme içeriyorsa, Safari'nin WebKit kuralı gereği kilitlenmesini önlemek için
          // yönlendirme bayrağından arındırılmış temiz bir Response nesnesi oluşturup sunuyoruz
          return new Response(response.body, {
            status: response.status,
            statusText: response.statusText,
            headers: response.headers
          });
        }

        return response;
      } catch (err) {
        const cached = await caches.match(event.request);
        if (cached) {
          // Önbellekteki yanıt yönlendirme barındırıyorsa Safari için temizle
          if (cached.redirected || (cached.status >= 300 && cached.status < 400)) {
            return new Response(cached.body, {
              status: cached.status,
              statusText: cached.statusText,
              headers: cached.headers
            });
          }
          return cached;
        }
        throw err;
      }
    })()
  );
});
