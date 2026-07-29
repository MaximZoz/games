/* Web Push service worker for Zozu Games PWA.
 * v5: системный пуш только когда PWA не в фокусе (свёрнуто).
 * В открытом приложении — без пушей на телефон (бейджи/realtime в UI).
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
  if (t.startsWith('game_turn_')) {
    const gameId = t.slice('game_turn_'.length);
    return gameId ? `/games/tictactoe/game/${gameId}` : '/games';
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

/**
 * PWA реально на экране и в фокусе.
 * На iOS при сворачивании visibility часто остаётся visible, а focused=false —
 * поэтому для подавления пуша требуем focused === true.
 */
function clientIsFocusedForeground(client) {
  if (!client) return false;
  if (client.visibilityState && client.visibilityState !== 'visible') {
    return false;
  }
  if ('focused' in client) {
    return client.focused === true;
  }
  // Старые движки без focused: ориентируемся только на visibility.
  return client.visibilityState === 'visible';
}

async function isPwaFocusedForeground() {
  const clientsList = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });
  for (const client of clientsList) {
    let sameOrigin = false;
    try {
      sameOrigin = new URL(client.url).origin === self.location.origin;
    } catch (_) {
      continue;
    }
    if (!sameOrigin) continue;
    if (clientIsFocusedForeground(client)) return true;
  }
  return false;
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
    data: { url: url, kind: data.kind || '' },
    tag: tag,
    renotify: true,
    silent: false,
    requireInteraction: false,
  };

  event.waitUntil(
    (async () => {
      // Любые системные пуши только когда приложение свёрнуто / не в фокусе.
      // В открытом PWA (чаты, игры, другой таб) — без баннера на iPhone.
      if (await isPwaFocusedForeground()) {
        return;
      }
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
