import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

JSFunction? _visibilityListener;
JSFunction? _focusListener;
bool _installed = false;

/// Убрать залипшие HtmlElementView от старых OAuth/auth кнопок.
void _purgeStalePlatformViews() {
  try {
    final hosts = web.document.querySelectorAll('flt-platform-view');
    for (var i = 0; i < hosts.length; i++) {
      final host = hosts.item(i);
      if (host == null) continue;
      final text = (host.textContent ?? '').trim();
      if (text.contains('Нет аккаунта') ||
          text.contains('Уже есть') ||
          text.contains('Google') ||
          text.contains('No account') ||
          text.contains('Already have')) {
        host.parentNode?.removeChild(host);
      }
    }
  } catch (_) {}
}

/// Поддерживает синхронизацию Flutter metrics с visualViewport на iOS.
/// Иначе hit-test остаётся со сдвигом, пока пользователь не ткнёт в TextField.
void installIosViewportSync() {
  if (_installed) return;
  _installed = true;
  _purgeStalePlatformViews();

  void sync() {
    try {
      if (web.window.scrollX != 0 || web.window.scrollY != 0) {
        web.window.scrollTo(web.ScrollToOptions(left: 0, top: 0));
      }
      final vv = web.window.visualViewport;
      if (vv != null && (vv.offsetTop != 0 || vv.pageTop != 0)) {
        web.window.scrollTo(web.ScrollToOptions(left: 0, top: 0));
      }
      web.window.dispatchEvent(web.Event('resize'));
    } catch (_) {}
  }

  void onVisibility(web.Event _) {
    if (web.document.visibilityState == 'visible') sync();
  }

  void onFocus(web.Event _) => sync();

  _visibilityListener = onVisibility.toJS;
  _focusListener = onFocus.toJS;
  web.document.addEventListener('visibilitychange', _visibilityListener!);
  web.window.addEventListener('focus', _focusListener!);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    sync();
    Future<void>.delayed(const Duration(milliseconds: 100), sync);
    Future<void>.delayed(const Duration(milliseconds: 400), sync);
  });

  WidgetsBinding.instance.addObserver(_ViewportLifecycleObserver(sync));
}

class _ViewportLifecycleObserver with WidgetsBindingObserver {
  _ViewportLifecycleObserver(this._sync);
  final void Function() _sync;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync();
    }
  }

  @override
  void didChangeMetrics() {
    // После metrics — ещё раз сбросить scroll (iOS клавиатура/Safari chrome).
    Future<void>.delayed(const Duration(milliseconds: 16), _sync);
  }
}
