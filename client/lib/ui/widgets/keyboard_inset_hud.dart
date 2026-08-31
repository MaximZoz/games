import 'package:flutter/material.dart';
import 'package:multigames_client/core/viewport_metrics.dart';
import 'package:multigames_client/ui/keyboard_inset.dart';

/// Диагностика раскладки под клавиатурой: `?insets=1` в адресе.
/// Нужна, чтобы поймать завышенный `viewInsets` на iOS PWA — там ни
/// логов, ни devtools под рукой.
bool _flagsRead = false;
bool _hudEnabled = false;
bool _fakeSafeArea = false;
double? _fakeInset;

/// Флаги читаются один раз со стартового адреса: go_router переписывает URL
/// при навигации, и параметры оттуда пропадают.
void _readFlags() {
  if (_flagsRead) return;
  _flagsRead = true;
  final query = Uri.base.queryParameters;
  _hudEnabled = query['insets'] == '1';
  _fakeSafeArea = query['fakesafe'] == '1';
  final raw = query['fakekb'];
  if (raw != null) {
    final value = double.tryParse(raw);
    if (value != null && value > 0) _fakeInset = value;
  }
}

bool keyboardInsetHudEnabled() {
  _readFlags();
  return _hudEnabled;
}

/// Подставная высота клавиатуры: `?fakekb=336`.
/// На десктопе софт-клавиатуры нет, а раскладку под ней проверять надо.
double? fakeKeyboardInset() {
  _readFlags();
  return _fakeInset;
}

/// Фокус стоит в текстовом поле? Подставная клавиатура «выезжает» только
/// тогда, как настоящая, иначе по приложению не походить.
bool _focusInTextField() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Оборачивает приложение подставным viewInsets, если задан `?fakekb=`.
class FakeKeyboardInset extends StatefulWidget {
  const FakeKeyboardInset({super.key, required this.child});

  final Widget child;

  @override
  State<FakeKeyboardInset> createState() => _FakeKeyboardInsetState();
}

class _FakeKeyboardInsetState extends State<FakeKeyboardInset> {
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    if (fakeKeyboardInset() != null) {
      FocusManager.instance.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    if (fakeKeyboardInset() != null) {
      FocusManager.instance.removeListener(_onFocusChanged);
    }
    super.dispose();
  }

  void _onFocusChanged() {
    final typing = _focusInTextField();
    if (typing == _typing || !mounted) return;
    setState(() => _typing = typing);
  }

  @override
  Widget build(BuildContext context) {
    final inset = fakeKeyboardInset();
    if (inset == null || !_typing) return widget.child;
    final media = MediaQuery.of(context);
    // Геометрия iPhone: чёлка сверху, home indicator снизу. Под клавиатурой
    // padding.bottom обнуляется — так же, как это делает платформа.
    final viewPadding = _fakeSafeArea
        ? media.viewPadding.copyWith(top: 59, bottom: 34)
        : media.viewPadding;
    return MediaQuery(
      data: media.copyWith(
        viewInsets: media.viewInsets.copyWith(bottom: inset),
        viewPadding: viewPadding,
        padding: viewPadding.copyWith(bottom: 0),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: inset,
            child: IgnorePointer(
              child: Container(
                color: const Color(0x99303030),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'клавиатура ${inset.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KeyboardInsetHud extends StatelessWidget {
  const KeyboardInsetHud({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final metrics = readViewportMetrics();
    final inset = media.viewInsets.bottom;
    final safe = sanitizeKeyboardInset(
      inset: inset,
      viewportHeight: media.size.height,
    );
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(0);
    final lines = <String>[
      'size ${fmt(media.size.width)}x${fmt(media.size.height)} dpr ${media.devicePixelRatio.toStringAsFixed(1)}',
      'viewInsets.bottom ${fmt(inset)} → clamp ${fmt(safe)}',
      'viewPadding t${fmt(media.viewPadding.top)} b${fmt(media.viewPadding.bottom)}',
      'innerHeight ${fmt(metrics.innerHeight)} visual ${fmt(metrics.visualHeight)}',
      'visualOffsetTop ${fmt(metrics.visualOffsetTop)} scrollY ${fmt(metrics.scrollY)}',
    ];
    return IgnorePointer(
      child: Container(
        color: const Color(0xCC000000),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF7CFC9B),
                  fontSize: 10,
                  height: 1.35,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
