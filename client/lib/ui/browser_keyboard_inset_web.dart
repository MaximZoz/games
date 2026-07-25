// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Оценка высоты клавиатуры через Visual Viewport API (iOS Safari / Chrome).
///
/// На мобильном вебе MediaQuery.viewInsets часто остаётся 0, а клавиатура
/// просто перекрывает canvas — без этого inset поле ввода оказывается под ней.
double readBrowserKeyboardInset() {
  final viewport = html.window.visualViewport;
  if (viewport == null) return 0;
  final height = (viewport.height ?? 0).toDouble();
  final offsetTop = (viewport.offsetTop ?? 0).toDouble();
  final windowHeight = (html.window.innerHeight ?? 0).toDouble();
  if (windowHeight <= 0 || height <= 0) return 0;
  final inset = windowHeight - height - offsetTop;
  if (inset.isNaN || inset.isInfinite) return 0;
  return inset < 0 ? 0.0 : inset;
}

void Function()? listenBrowserKeyboardInset(
  void Function(double inset) onChanged,
) {
  void handle([_]) => onChanged(readBrowserKeyboardInset());

  final viewport = html.window.visualViewport;
  viewport?.addEventListener('resize', handle);
  viewport?.addEventListener('scroll', handle);
  html.window.addEventListener('resize', handle);

  // Первичное значение после подписки.
  handle();

  return () {
    viewport?.removeEventListener('resize', handle);
    viewport?.removeEventListener('scroll', handle);
    html.window.removeEventListener('resize', handle);
  };
}
