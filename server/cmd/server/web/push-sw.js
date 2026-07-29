/* Web Push service worker for Zozu Games PWA.
 * v2: deep-link через tag + Cache (iOS часто теряет notification.data).
 */
/* eslint-disable no-undef */

const PENDING_CACHE = 'zozu-push-pending-v1';
const PENDING_KEY = '/__pending_nav';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

function resolveTargetUrl(raw) {
  try {
    return new URL(raw || '/', self.location.origin);
  } catch (_) {
    return new URL('/', self.location.origin);
  }
}

function appPathFromUrl(url) {
  const path = `${url.pathname}${url.search}${url.hash}` || '/';
  return path;
}

/** Fallback, когда iOS отдаёт пустой notification.data при клике. */
function pathFromTag(tag) {
  const t = (tag && String(tag)) || '';
  if (t.startsWith('chat_')) {
    const id = t.slice('chat_'.length);
    return id ? `/chats/${id}` : '/chats';
  }
  if (t === 'friend_request') return '/friends';
  if (t.startsWith('game_invite_')) {
    const lobbyId = t.slice('game_invite_'.length);
    return lobbyId ? `/games/tictactoe/lobby/${lobbyId}` : '/games';
  }
  if (t.startsWith('achievement_')) return '/achievements';
  if (t.startsWith('reward_gift_')) return '/inventory';
  if (t === 'daily_reward') return '/coins/login';
  return null;
}

async function setPendingPath(path) {
  try {
    const cache = await caches.open(PENDING_CACHE);
    await cache.put(
      PENDING_KEY,
      new Response(JSON.stringify({ path, ts: Date.now() }), {
        headers: { 'Content-Type': 'application/json' },
      }),
    );
  } catch (err) {
    console.warn('[push-sw] setPendingPath failed', err);
  }
}

function resolveClickPath(notification) {
  const dataUrl =
    notification.data && notification.data.url
      ? String(notification.data.url)
      : '';
  const fromTag = pathFromTag(notification.tag);
  if (dataUrl && dataUrl !== '/') {
    return appPathFromUrl(resolveTargetUrl(dataUrl));
  }
  if (fromTag) return fromTag;
  return '/';
}

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

  const title = (data.title && String(data.title)) || 'Zozu Games';
  const body = data.body != null ? String(data.body) : '';
  const tag = data.tag || 'zozu';
  const url = data.url || pathFromTag(tag) || '/';
  const options = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { url: url },
    tag: tag,
    renotify: true,
    silent: false,
    requireInteraction: false,
  };

  event.waitUntil(
    (async () => {
      const path = appPathFromUrl(resolveTargetUrl(url));
      // Заранее кладём deep-link: на iOS data при клике часто пустой.
      if (path && path !== '/') {
        await setPendingPath(path);
      }
      await self.registration.showNotification(title, options);
    })().catch((err) => {
      console.warn('[push-sw] push handler failed', err);
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const appPath = resolveClickPath(event.notification);
  const target = resolveTargetUrl(appPath);

  event.waitUntil(
    (async () => {
      await setPendingPath(appPath);

      const all = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true,
      });
      for (const client of all) {
        let sameOrigin = false;
        try {
          sameOrigin = new URL(client.url).origin === self.location.origin;
        } catch (_) {}
        if (!sameOrigin) continue;
        if ('focus' in client) {
          try {
            await client.focus();
          } catch (_) {}
        }
        // Не navigate() — reload + splash. postMessage + pending cache.
        try {
          client.postMessage({ type: 'notification_click', url: appPath });
        } catch (_) {}
        return;
      }
      if (self.clients.openWindow) {
        await self.clients.openWindow(target.href);
      }
    })(),
  );
});
