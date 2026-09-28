import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';
import 'package:multigames_client/core/gamepad/gamepad_grid.dart';
import 'package:multigames_client/core/gamepad/gamepad_scope.dart';
import 'package:multigames_client/core/gamepad/gamepad_text.dart';
import 'package:multigames_client/l10n/l10n.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

enum GamepadKeyboardLayout { latin, cyrillic, digits }

class GamepadKeyboardController extends ChangeNotifier {
  GamepadKeyboardController();

  static final GamepadKeyboardController instance = GamepadKeyboardController();

  bool _visible = false;
  int _generation = 0;
  bool get visible => _visible;

  /// Растёт при каждом `hide`, чтобы отменить отложенный `show`.
  int get generation => _generation;

  void show() {
    hideSoftKeyboard();
    if (_visible) return;
    _visible = true;
    notifyListeners();
  }

  /// Системная клавиатура не должна перекрывать панель геймпада.
  static void hideSoftKeyboard() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (instance._visible) {
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      }
    });
  }

  void hide() {
    _generation++;
    if (!_visible) return;
    _visible = false;
    notifyListeners();
  }

  void toggle() => _visible ? hide() : show();

  @visibleForTesting
  void reset() {
    _visible = false;
    _generation++;
  }
}

class GamepadKbKey {
  const GamepadKbKey(this.id, {this.label, this.icon, this.width = 1});

  final String id;
  final String? label;
  final IconData? icon;
  final double width;
}

/// Раскладки экранной клавиатуры для геймпада.
List<List<GamepadKbKey>> gamepadKeyboardRows({
  required GamepadKeyboardLayout layout,
  required bool shift,
}) {
  List<String> chars(String raw) => raw.split('');
  String map(String s) => shift ? s.toUpperCase() : s;
  List<GamepadKbKey> row(String raw) =>
      [for (final c in chars(raw)) GamepadKbKey(c, label: map(c))];

  switch (layout) {
    case GamepadKeyboardLayout.digits:
      return [
        row('1234567890'),
        row('-/:;()₽&@"'),
        row('.,?!\'#+*='),
        [
          const GamepadKbKey('layout', label: 'ABC', width: 1.4),
          const GamepadKbKey('space', label: ' ', width: 4),
          const GamepadKbKey('backspace', icon: Icons.backspace_outlined),
          const GamepadKbKey('enter', icon: Icons.keyboard_return_rounded),
        ],
      ];
    case GamepadKeyboardLayout.cyrillic:
      return [
        row('йцукенгшщзх'),
        row('фывапролджэ'),
        [
          const GamepadKbKey('shift', icon: Icons.arrow_upward_rounded),
          ...row('ячсмитьбю'),
          const GamepadKbKey('backspace', icon: Icons.backspace_outlined),
        ],
        [
          const GamepadKbKey('layout', label: '123', width: 1.3),
          const GamepadKbKey('lang', label: 'EN', width: 1.2),
          const GamepadKbKey('space', label: ' ', width: 3.4),
          const GamepadKbKey('enter', icon: Icons.keyboard_return_rounded),
        ],
      ];
    case GamepadKeyboardLayout.latin:
      return [
        row('qwertyuiop'),
        row('asdfghjkl'),
        [
          const GamepadKbKey('shift', icon: Icons.arrow_upward_rounded),
          ...row('zxcvbnm'),
          const GamepadKbKey('backspace', icon: Icons.backspace_outlined),
        ],
        [
          const GamepadKbKey('layout', label: '123', width: 1.3),
          const GamepadKbKey('lang', label: 'РУ', width: 1.2),
          const GamepadKbKey('space', label: ' ', width: 3.4),
          const GamepadKbKey('enter', icon: Icons.keyboard_return_rounded),
        ],
      ];
  }
}

class GamepadKeyboardPanel extends StatefulWidget {
  const GamepadKeyboardPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<GamepadKeyboardPanel> createState() => _GamepadKeyboardPanelState();
}

class _GamepadKeyboardPanelState extends State<GamepadKeyboardPanel> {
  GamepadKeyboardLayout _layout = GamepadKeyboardLayout.latin;
  bool _shift = false;
  int _row = 0;
  int _col = 0;

  List<List<GamepadKbKey>> get _rows =>
      gamepadKeyboardRows(layout: _layout, shift: _shift);

  GamepadKbKey get _current {
    final rows = _rows;
    final r = _row.clamp(0, rows.length - 1);
    final row = rows[r];
    final c = _col.clamp(0, row.length - 1);
    return row[c];
  }

  bool _onAction(GamepadAction action) {
    if (action == GamepadAction.shoulderL ||
        action == GamepadAction.shoulderR) {
      return false;
    }
    if (action.isDirection) {
      final rows = _rows;
      if (action == GamepadAction.up || action == GamepadAction.down) {
        final nextRow = action == GamepadAction.up ? _row - 1 : _row + 1;
        if (nextRow < 0 || nextRow >= rows.length) return true;
        setState(() {
          _row = nextRow;
          _col = _col.clamp(0, rows[_row].length - 1);
        });
        return true;
      }
      setState(() {
        _col = cycleIndex(_col, rows[_row].length, action);
      });
      return true;
    }
    if (action == GamepadAction.confirm) {
      _activate(_current);
      return true;
    }
    if (action == GamepadAction.cancel) {
      widget.onClose();
      return true;
    }
    if (action == GamepadAction.actionY) {
      if (!GamepadTextEditing.backspace()) {
        widget.onClose();
      }
      return true;
    }
    if (action == GamepadAction.actionX) {
      setState(_cycleLayout);
      return true;
    }
    if (action == GamepadAction.menu) {
      GamepadTextEditing.insert('\n');
      return true;
    }
    if (action == GamepadAction.select) {
      setState(() => _shift = !_shift);
      return true;
    }
    return true;
  }

  void _cycleLayout() {
    _layout = switch (_layout) {
      GamepadKeyboardLayout.latin => GamepadKeyboardLayout.cyrillic,
      GamepadKeyboardLayout.cyrillic => GamepadKeyboardLayout.digits,
      GamepadKeyboardLayout.digits => GamepadKeyboardLayout.latin,
    };
    _shift = false;
    _row = 0;
    _col = 0;
  }

  void _activate(GamepadKbKey key) {
    switch (key.id) {
      case 'shift':
        setState(() => _shift = !_shift);
      case 'layout':
        setState(_cycleLayout);
      case 'lang':
        setState(() {
          _layout = _layout == GamepadKeyboardLayout.latin
              ? GamepadKeyboardLayout.cyrillic
              : GamepadKeyboardLayout.latin;
          _shift = false;
          _row = 0;
          _col = 0;
        });
      case 'backspace':
        GamepadTextEditing.backspace();
      case 'enter':
        GamepadTextEditing.insert('\n');
      case 'space':
        GamepadTextEditing.insert(' ');
      default:
        GamepadTextEditing.insert(key.label ?? key.id);
        if (_shift) setState(() => _shift = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final narrow = isNarrow(context);
    final rows = _rows;
    return GamepadScope(
      onAction: _onAction,
      child: Material(
        color: AppColors.surfaceUnified.withValues(alpha: 0.97),
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(narrow ? 6 : 12, 8, narrow ? 6 : 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.gamepadKeyboardTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.keyboard_hide_rounded),
                    ),
                  ],
                ),
                for (var r = 0; r < rows.length; r++) ...[
                  if (r > 0) const SizedBox(height: 4),
                  Row(
                    children: [
                      for (var c = 0; c < rows[r].length; c++) ...[
                        if (c > 0) const SizedBox(width: 4),
                        Expanded(
                          flex: (rows[r][c].width * 10).round(),
                          child: _KbKeyTile(
                            keyData: rows[r][c],
                            selected: r == _row && c == _col,
                            onTap: () {
                              setState(() {
                                _row = r;
                                _col = c;
                              });
                              _activate(rows[r][c]);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KbKeyTile extends StatelessWidget {
  const _KbKeyTile({
    required this.keyData,
    required this.selected,
    required this.onTap,
  });

  final GamepadKbKey keyData;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = keyData.id == 'space'
        ? context.l10n.gamepadKeyboardSpace
        : (keyData.label ?? '');
    return Material(
      color: selected ? AppColors.accentStart : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accentStart : AppColors.accentSoft,
              width: selected ? 2 : 1,
            ),
          ),
          child: keyData.icon != null
              ? Icon(
                  keyData.icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textPrimary,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
