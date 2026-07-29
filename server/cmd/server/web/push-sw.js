/* Web Push service worker for Zozu Games PWA.
 * v3: game_turn push + не показывать, если уже смотрим этот матч.
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

function pathOnly(path) {
  try {
    return new URL(path, self.location.origin).pathname;
  } catch (_) {
    return String(path || '').split('?')[0].split('#')[0];
  }
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
 * Не показывать «Ваш ход», если в этом же браузере/PWA уже открыт
 * и видим именно этот матч. Свёрнутое приложение / другой таб — показывать.
 */
async function shouldSuppressGameTurn(data) {
  const kind = data && data.kind != null ? String(data.kind) : '';
  const tag = data && data.tag != null ? String(data.tag) : '';
  if (kind !== 'game_turn' && !tag.startsWith('game_turn_')) {
    return false;
  }
  const targetPath = pathOnly(
    data.url || pathFromTag(tag) || '/games',
  );
  if (!targetPath.startsWith('/games/tictactoe/game/')) {
    return false;
  }

  const clientsList = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });
  for (const client of clientsList) {
    let sameOrigin = false;
    let clientPath = '';
    try {
      const u = new URL(client.url);
      sameOrigin = u.origin === self.location.origin;
      clientPath = u.pathname;
    } catch (_) {
      continue;
    }
    if (!sameOrigin) continue;
    if (clientPath !== targetPath) continue;
    // Свёрнуто / в фоне — уведомление нужно.
    if (client.visibilityState && client.visibilityState !== 'visible') {
      continue;
    }
    // Другая вкладка браузера без фокуса — уведомление нужно.
    if ('focused' in client && client.focused === false) {
      continue;
    }
    return true;
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
      if (await shouldSuppressGameTurn(data)) {
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
