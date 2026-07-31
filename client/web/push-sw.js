/* Web Push service worker for Zozu Games PWA.
 * v8: глушим пуш, если Flutter сообщает что открыт тот же чат/матч
 *     (на iOS client.focused часто false даже когда PWA на экране).
 * v7: clear_all_notifications при logout (снять баннеры + pending).
 * v6: при клике / открытии из пуша снимаем уведомление из шторки (iOS).
 * v5: системный пуш только когда PWA не в фокусе (свёрнуто).
 */
/* eslint-disable no-undef */

const PENDING_CACHE = 'zozu-push-pending-v1';
const PENDING_KEY = '/__pending_nav';
/** Пока Flutter шлёт heartbeat — считаем экран «смотрит» приложение. */
const VIEWER_TTL_MS = 25000;

/** Состояние экрана из Flutter (надёжнее client.focused на iOS). */
let viewer = {
  path: '',
  foreground: false,
  at: 0,
};

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

function stripQueryHash(path) {
  const p = String(path || '');
  const q = p.indexOf('?');
  const h = p.indexOf('#');
  let end = p.length;
  if (q >= 0) end = Math.min(end, q);
  if (h >= 0) end = Math.min(end, h);
  return p.slice(0, end) || '/';
}

/** Fallback, когда iOS отдаёт пустой notification.data при клике. */
function pathFromTag(tag) {
  const t = (tag && String(tag)) || '';
  if (t.startsWith('chat_')) {
    const id = t.slice('chat_'.length);
    return id ? `/chats/${id}` : '/chats';
  }
  if (t === 'friend_request') return '/friends?tab=incoming';
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

/** Обратный map path → tag для снятия баннера после открытия. */
function tagFromPath(path) {
  const p = String(path || '');
  const chat = p.match(/^\/chats\/([^/?#]+)/);
  if (chat && chat[1]) return `chat_${chat[1]}`;
  if (p === '/friends' || p.startsWith('/friends?') || p.startsWith('/friends/')) {
    return 'friend_request';
  }
  const lobby = p.match(/^\/games\/tictactoe\/lobby\/([^/?#]+)/);
  if (lobby && lobby[1]) return `game_invite_${lobby[1]}`;
  const game = p.match(/^\/games\/tictactoe\/game\/([^/?#]+)/);
  if (game && game[1]) return `game_turn_${game[1]}`;
  if (p === '/coins/login' || p.startsWith('/coins/login?')) {
    return 'daily_reward';
  }
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
 * На iOS одного event.notification.close() часто недостаточно —
 * баннер остаётся в Notification Center. Снимаем все с тем же tag
 * и, при необходимости, по префиксу path.
 */
async function closeShownNotifications({ tag, path } = {}) {
  try {
    if (tag) {
      const byTag = await self.registration.getNotifications({ tag: String(tag) });
      for (const n of byTag) {
        try {
          n.close();
        } catch (_) {}
      }
    }
  } catch (err) {
    console.warn('[push-sw] getNotifications(tag) failed', err);
  }

  const p = path != null ? String(path) : '';
  if (!p || p === '/') return;

  const exactTag = tagFromPath(p);
  if (exactTag && exactTag !== tag) {
    try {
      const byPath = await self.registration.getNotifications({ tag: exactTag });
      for (const n of byPath) {
        try {
          n.close();
        } catch (_) {}
      }
    } catch (_) {}
  }

  // achievement_*/reward_gift_* — конкретный tag неизвестен из path.
  if (p.startsWith('/achievements') || p.startsWith('/inventory')) {
    try {
      const all = await self.registration.getNotifications();
      for (const n of all) {
        const t = (n.tag && String(n.tag)) || '';
        if (p.startsWith('/achievements') && t.startsWith('achievement_')) {
          try {
            n.close();
          } catch (_) {}
        }
        if (p.startsWith('/inventory') && t.startsWith('reward_gift_')) {
          try {
            n.close();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
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

function isViewerReportedlyForeground() {
  if (!viewer.foreground) return false;
  return Date.now() - viewer.at < VIEWER_TTL_MS;
}

/**
 * Пуш про тот же экран, который сейчас открыт (чат / матч / лобби).
 * Другие чаты/игры — не глушим.
 */
function pathsMatchForSuppress(activePath, notifPath) {
  const a = stripQueryHash(activePath);
  const n = stripQueryHash(notifPath);
  if (!a || !n || a === '/' || n === '/') return false;
  if (a === n) return true;

  const chatA = a.match(/^\/chats\/([^/]+)/);
  const chatN = n.match(/^\/chats\/([^/]+)/);
  if (chatA && chatN) return chatA[1] === chatN[1];

  const gameA = a.match(/^\/games\/tictactoe\/game\/([^/]+)/);
  const gameN = n.match(/^\/games\/tictactoe\/game\/([^/]+)/);
  if (gameA && gameN) return gameA[1] === gameN[1];

  const lobbyA = a.match(/^\/games\/tictactoe\/lobby\/([^/]+)/);
  const lobbyN = n.match(/^\/games\/tictactoe\/lobby\/([^/]+)/);
  if (lobbyA && lobbyN) return lobbyA[1] === lobbyN[1];

  return false;
}

async function shouldSuppressPush(notifPath) {
  // Классика: окно в фокусе (Desktop / когда iOS правильно отдаёт focused).
  if (await isPwaFocusedForeground()) return true;
  // iOS: focused часто false на открытом PWA — смотрим heartbeat из Flutter.
  if (
    isViewerReportedlyForeground() &&
    pathsMatchForSuppress(viewer.path, notifPath)
  ) {
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
      const path = appPathFromUrl(resolveTargetUrl(url));
      if (await shouldSuppressPush(path)) {
        return;
      }
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
  const notification = event.notification;
  const appPath = resolveClickPath(notification);
  const tag = notification.tag || '';
  const target = resolveTargetUrl(appPath);

  try {
    notification.close();
  } catch (_) {}

  event.waitUntil(
    (async () => {
      await closeShownNotifications({ tag, path: appPath });
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
          client.postMessage({
            type: 'notification_click',
            url: appPath,
            tag: tag || null,
          });
        } catch (_) {}
        return;
      }
      if (self.clients.openWindow) {
        await self.clients.openWindow(target.href);
      }
    })(),
  );
});

async function clearPendingPath() {
  try {
    const cache = await caches.open(PENDING_CACHE);
    await cache.delete(PENDING_KEY);
  } catch (_) {}
}

async function closeAllShownNotifications() {
  try {
    const list = await self.registration.getNotifications();
    for (const n of list) {
      try {
        n.close();
      } catch (_) {}
    }
  } catch (err) {
    console.warn('[push-sw] closeAllShownNotifications failed', err);
  }
}

// Приложение просит снять баннеры после перехода по deep-link
// (когда iOS открыл PWA без надёжного notificationclick.close).
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (!data || !data.type) return;

  if (data.type === 'active_route') {
    const path = data.path != null ? String(data.path) : '';
    const foreground = data.foreground === true;
    viewer = {
      path: path,
      foreground: foreground,
      at: Date.now(),
    };
    return;
  }

  if (data.type === 'clear_all_notifications') {
    event.waitUntil(
      (async () => {
        await closeAllShownNotifications();
        await clearPendingPath();
      })(),
    );
    return;
  }
  if (data.type !== 'clear_notifications') return;
  const tag = data.tag != null ? String(data.tag) : '';
  const path = data.path != null ? String(data.path) : '';
  event.waitUntil(closeShownNotifications({ tag: tag || undefined, path }));
});
