/* Web Push service worker for Zozu Games PWA.
 * v12: пока приложение на экране (Flutter foreground) — глушим ВСЕ пуши;
 *      в фоне/свёрнутом — доставляем. Не используем Clients.visibility alone.
 * v11: клик не затирает deep-link на iOS; chat_id fallback.
 * v10: viewer в Cache (SW убивается между push — память пустая).
 * v9: в foreground глушим ВСЕ пуши.
 * v8: глушим пуш, если открыт тот же чат/матч.
 * v7: clear_all_notifications при logout.
 * v6: при клике снимаем уведомление из шторки (iOS).
 * v5: системный пуш только когда PWA не в фокусе.
 */
/* eslint-disable no-undef */

const PENDING_CACHE = 'zozu-push-pending-v1';
const PENDING_KEY = '/__pending_nav';
const VIEWER_CACHE = 'zozu-push-viewer-v1';
const VIEWER_KEY = '/__viewer';
/** Flutter шлёт heartbeat ~каждые 4с. Короткий TTL: после сворачивания
 *  pagehide/visibility → foreground:false; иначе пуши снова идут. */
const VIEWER_TTL_MS = 12000;

/** Состояние экрана из Flutter (надёжнее client.focused на iOS). */
let viewer = {
  path: '',
  foreground: false,
  at: 0,
};

async function saveViewerState(state) {
  try {
    const cache = await caches.open(VIEWER_CACHE);
    await cache.put(
      VIEWER_KEY,
      new Response(JSON.stringify(state), {
        headers: { 'Content-Type': 'application/json' },
      }),
    );
  } catch (err) {
    console.warn('[push-sw] saveViewerState failed', err);
  }
}

async function loadViewerState() {
  try {
    const cache = await caches.open(VIEWER_CACHE);
    const res = await cache.match(VIEWER_KEY);
    if (!res) return null;
    return await res.json();
  } catch (_) {
    return null;
  }
}

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

async function peekPendingPath() {
  try {
    const cache = await caches.open(PENDING_CACHE);
    const res = await cache.match(PENDING_KEY);
    if (!res) return null;
    const parsed = await res.json();
    const path = parsed && parsed.path != null ? String(parsed.path) : '';
    return path || null;
  } catch (_) {
    return null;
  }
}

/** iOS иногда отдаёт data строкой JSON, а не объектом. */
function readNotificationData(notification) {
  let data = notification && notification.data;
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (_) {
      data = null;
    }
  }
  return data && typeof data === 'object' ? data : {};
}

/**
 * Путь из клика. null = неизвестно (не затирать pending Cache).
 * Не возвращаем голый '/chats' как «успех», если есть chat_id.
 */
function resolveClickPath(notification) {
  const data = readNotificationData(notification);
  const dataUrl = data.url != null ? String(data.url) : '';
  const fromTag = pathFromTag(notification.tag);
  const chatId = data.chat_id != null ? String(data.chat_id).trim() : '';
  const fromChatId = chatId ? `/chats/${chatId}` : null;

  if (dataUrl && dataUrl !== '/' && dataUrl !== '/chats') {
    return appPathFromUrl(resolveTargetUrl(dataUrl));
  }
  if (fromTag && fromTag !== '/chats') return fromTag;
  if (fromChatId) return fromChatId;
  if (dataUrl === '/chats' || fromTag === '/chats') return '/chats';
  return null;
}

/** Насколько путь «конкретный» для выбора между click и pending. */
function pathSpecificity(path) {
  const p = String(path || '');
  if (!p || p === '/') return 0;
  if (p === '/chats' || p === '/games' || p === '/friends') return 1;
  if (/^\/chats\/[^/?#]+/.test(p)) return 3;
  if (/^\/games\/tictactoe\/(game|lobby)\/[^/?#]+/.test(p)) return 3;
  return 2;
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
 * Окно реально в фокусе (Desktop / корректный Safari).
 * На iOS при сворачивании visibility часто остаётся 'visible', а focused=false —
 * поэтому НЕ считаем visibility alone достаточным для «приложение открыто».
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

function viewerStateIsFreshForeground(state) {
  if (!state || state.foreground !== true) return false;
  const at = typeof state.at === 'number' ? state.at : 0;
  return Date.now() - at < VIEWER_TTL_MS;
}

async function getFreshViewerState() {
  if (viewerStateIsFreshForeground(viewer)) return viewer;
  const saved = await loadViewerState();
  if (viewerStateIsFreshForeground(saved)) return saved;
  return null;
}

async function shouldSuppressPush(_notifPath) {
  // 1) Окно реально в фокусе (Desktop / корректный Safari focused).
  if (await isPwaFocusedForeground()) return true;
  // 2) Flutter сообщает, что документ видим (приложение на экране, не свёрнуто).
  //    Не смотрим Clients.visibility — на iOS он часто остаётся visible в фоне.
  //    Flutter на pagehide/visibilitychange шлёт foreground:false.
  if (await getFreshViewerState()) return true;
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
  const chatId =
    data.chat_id != null && String(data.chat_id).trim()
      ? String(data.chat_id).trim()
      : '';
  const options = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      url: url,
      kind: data.kind || '',
      chat_id: chatId,
      tag: tag,
    },
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
  const resolved = resolveClickPath(notification);
  const tag = notification.tag || '';

  try {
    notification.close();
  } catch (_) {}

  event.waitUntil(
    (async () => {
      const pending = await peekPendingPath();
      let appPath = resolved;
      // iOS: data/tag пустые → не затираем pending из push event.
      if (!appPath || pathSpecificity(appPath) < pathSpecificity(pending)) {
        if (pending && pathSpecificity(pending) > 0) {
          appPath = pending;
        }
      }
      if (!appPath) appPath = '/';

      await closeShownNotifications({ tag, path: appPath });
      if (appPath && appPath !== '/') {
        await setPendingPath(appPath);
      }

      const target = resolveTargetUrl(appPath);
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
    // jsify/structured clone: true | 'true' | 1
    const foreground =
      data.foreground === true ||
      data.foreground === 'true' ||
      data.foreground === 1;
    viewer = {
      path: path,
      foreground: foreground,
      at: Date.now(),
    };
    event.waitUntil(saveViewerState(viewer));
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
