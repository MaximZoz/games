/* Web Push service worker for Zozu Games PWA.
 * Не зависит от Flutter cache SW — регистрируется из Dart.
 * iOS (установленная PWA): push обязан всегда показать user-visible notification.
 */
/* eslint-disable no-undef */

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', (event) => {
  let data = {
    title: 'Zozu Games',
    body: '',
    url: '/',
    tag: 'zozu',
  };
  try {
    if (event.data) {
      const parsed = event.data.json();
      data = Object.assign(data, parsed || {});
    }
  } catch (_) {
    try {
      const text = event.data && event.data.text();
      if (text) data.body = text;
    } catch (__) {}
  }

  // На iOS push без showNotification дропается / считается silent.
  const title = (data.title && String(data.title)) || 'Zozu Games';
  const body = data.body != null ? String(data.body) : '';
  const options = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { url: data.url || '/' },
    tag: data.tag || 'zozu',
    renotify: true,
    silent: false,
    requireInteraction: false,
  };

  event.waitUntil(
    self.registration.showNotification(title, options).catch((err) => {
      console.warn('[push-sw] showNotification failed', err);
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    (async () => {
      const all = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (const client of all) {
        if ('focus' in client) {
          await client.focus();
          if ('navigate' in client) {
            try {
              await client.navigate(targetUrl);
            } catch (_) {}
          } else {
            client.postMessage({ type: 'notification_click', url: targetUrl });
          }
          return;
        }
      }
      if (self.clients.openWindow) {
        await self.clients.openWindow(targetUrl);
      }
    })(),
  );
});
