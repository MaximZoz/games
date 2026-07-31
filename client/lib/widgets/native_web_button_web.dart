import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Map<String, VoidCallback> _tapCallbacks = {};
final Map<String, String> _hrefs = {};
final Map<String, String> _labels = {};
final Set<String> _registered = {};

void _registerTapFactory(String viewType) {
  if (_registered.contains(viewType)) return;
  _registered.add(viewType);
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    final btn = web.HTMLButtonElement()
      ..type = 'button'
      ..textContent = _labels[viewType] ?? '';
    btn.style.cssText = '''
      display:flex;align-items:center;justify-content:center;
      width:100%;height:100%;margin:0;padding:0;box-sizing:border-box;
      border:none;background:transparent;cursor:pointer;
      color:#4F46E5;font:600 14px system-ui,-apple-system,sans-serif;
      -webkit-tap-highlight-color:transparent;
    ''';
    void onClick(web.Event _) {
      _tapCallbacks[viewType]?.call();
    }

    btn.addEventListener('click', onClick.toJS);
    return btn;
  });
}

void _registerLinkFactory(String viewType) {
  if (_registered.contains(viewType)) return;
  _registered.add(viewType);
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    final a = web.HTMLAnchorElement()
      ..href = _hrefs[viewType] ?? '#'
      ..textContent = _labels[viewType] ?? '';
    // Без target=_blank — top-level в той же PWA (Safari UA), не in-app WebView.
    a.style.cssText = '''
      display:flex;align-items:center;justify-content:center;
      width:100%;height:100%;margin:0;padding:0;box-sizing:border-box;
      border:1.5px solid rgba(30,40,80,0.22);border-radius:14px;
      background:#fff;text-decoration:none;cursor:pointer;
      color:#1a1a2e;font:600 14px system-ui,-apple-system,sans-serif;
      -webkit-tap-highlight-color:transparent;
    ''';
    void onClick(web.Event _) {
      final href = _hrefs[viewType];
      if (href != null && href.isNotEmpty) a.href = href;
      _tapCallbacks[viewType]?.call();
    }

    a.addEventListener('click', onClick.toJS);
    return a;
  });
}

/// Нативный DOM-кнопка поверх Flutter canvas — свой hit-test браузера.
class NativeWebTapTarget extends StatefulWidget {
  const NativeWebTapTarget({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 48,
    this.style,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final TextStyle? style;

  @override
  State<NativeWebTapTarget> createState() => _NativeWebTapTargetState();
}

class _NativeWebTapTargetState extends State<NativeWebTapTarget> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'mg-native-tap-${identityHashCode(this)}';
    _labels[_viewType] = widget.label;
    _tapCallbacks[_viewType] = widget.onTap;
    _registerTapFactory(_viewType);
  }

  @override
  void didUpdateWidget(covariant NativeWebTapTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _labels[_viewType] = widget.label;
    _tapCallbacks[_viewType] = widget.onTap;
  }

  @override
  void dispose() {
    _tapCallbacks.remove(_viewType);
    _labels.remove(_viewType);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}

/// Нативный <a> для OAuth: клик = настоящая навигация браузера (user gesture).
class NativeWebOutlinedLink extends StatefulWidget {
  const NativeWebOutlinedLink({
    super.key,
    required this.label,
    required this.href,
    this.height = 48,
    this.onBeforeNavigate,
  });

  final String label;
  final String href;
  final double height;
  final VoidCallback? onBeforeNavigate;

  @override
  State<NativeWebOutlinedLink> createState() => _NativeWebOutlinedLinkState();
}

class _NativeWebOutlinedLinkState extends State<NativeWebOutlinedLink> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'mg-native-link-${identityHashCode(this)}';
    _labels[_viewType] = widget.label;
    _hrefs[_viewType] = widget.href;
    _tapCallbacks[_viewType] = () => widget.onBeforeNavigate?.call();
    _registerLinkFactory(_viewType);
  }

  @override
  void didUpdateWidget(covariant NativeWebOutlinedLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    _labels[_viewType] = widget.label;
    _hrefs[_viewType] = widget.href;
    _tapCallbacks[_viewType] = () => widget.onBeforeNavigate?.call();
  }

  @override
  void dispose() {
    _tapCallbacks.remove(_viewType);
    _labels.remove(_viewType);
    _hrefs.remove(_viewType);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(
        key: ValueKey(widget.href),
        viewType: _viewType,
      ),
    );
  }
}
