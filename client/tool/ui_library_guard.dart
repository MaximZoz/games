import 'dart:io';

/// Падает, если в `client/lib` появился цвет не из UI-библиотеки.
///
/// Литералы `Colors.*` и `Color(0x…)` / `Color.from…` можно писать только в
/// `client/packages/multigames_ui` и `client/packages/multigames_game_kit`
/// (`AppColors`, `GamePalette`). Эти пакеты проверка не читает.
///
/// Уже лежащий в репозитории код записан в [baselineName]. Новое вхождение
/// роняет сборку. `Colors.transparent` не считается цветом оформления.
/// Строка с пометкой `ui-library-allow` пропускается: так оставляют цвет
/// правила игры, которого нет в палитре.
const baselineName = 'tool/ui_library_baseline.txt';

final _colors = RegExp(r'\bColors\.([A-Za-z_][A-Za-z0-9_]*)');
final _hex = RegExp(r'\bColor\(\s*(0x[0-9A-Fa-f]+)');
final _from = RegExp(r'\bColor\.from[A-Za-z0-9]*');

class UiLibraryHit {
  const UiLibraryHit(
      {required this.path, required this.line, required this.token});

  final String path;
  final int line;
  final String token;

  String get key => '$path\t$token';
}

class UiLibraryReport {
  const UiLibraryReport({required this.added, required this.removed});

  final List<String> added;
  final List<String> removed;

  bool get isClean => added.isEmpty && removed.isEmpty;

  String format() {
    final lines = <String>[];
    if (added.isNotEmpty) {
      lines.add(
        'Цвет вне UI-библиотеки. Возьми его из AppColors или GamePalette '
        '(package:multigames_ui / package:multigames_game_kit).',
      );
      lines.add(
        'Colors.transparent можно оставить. Цвет правила игры, которого нет '
        'в палитре, помечай в той же строке: // ui-library-allow',
      );
      lines.addAll(added);
    }
    if (removed.isNotEmpty) {
      if (lines.isNotEmpty) lines.add('');
      lines.add(
        'В базе больше вхождений, чем в коде. После удаления литерала обнови '
        'базу: dart run tool/ui_library_guard.dart --write-baseline',
      );
      lines.addAll(removed);
    }
    return lines.join('\n');
  }
}

void main(List<String> args) {
  final root = findClientRoot();
  final hits = scanClientLib(root);
  final baselineFile = File('${root.path}/$baselineName');
  if (args.contains('--write-baseline')) {
    baselineFile.writeAsStringSync('${formatBaseline(hits)}\n');
    stdout
        .writeln('Записал $baselineName (${countHits(hits).length} записей).');
    return;
  }
  final report = diffHits(hits, loadBaseline(baselineFile));
  if (!report.isClean) {
    stderr.writeln(report.format());
    exitCode = 1;
  }
}

Directory findClientRoot() {
  final start = Directory.current.absolute;
  final queue = <Directory>[start, Directory('${start.path}/client')];
  var walk = start;
  while (true) {
    final parent = walk.parent;
    if (parent.path == walk.path) break;
    queue.add(parent);
    walk = parent;
  }
  for (final dir in queue) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;
    final text = pubspec.readAsStringSync();
    if (RegExp(r'^name:\s*multigames_client\s*$', multiLine: true)
        .hasMatch(text)) {
      return dir;
    }
  }
  throw StateError('Не найден корень client (пакет multigames_client).');
}

List<UiLibraryHit> scanClientLib(Directory root) {
  final lib = Directory('${root.path}/lib');
  final hits = <UiLibraryHit>[];
  if (!lib.existsSync()) return hits;
  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final relative = _relative(root, entity);
    if (_skipped(relative)) continue;
    hits.addAll(findUiLibraryHits(entity.readAsStringSync(), path: relative));
  }
  return hits;
}

bool _skipped(String relative) {
  if (relative.endsWith('.g.dart')) return true;
  if (relative.startsWith('lib/l10n/app_localizations')) return true;
  return false;
}

String _relative(Directory root, File file) {
  final rootPath = root.absolute.path;
  var path = file.absolute.path;
  if (path.startsWith(rootPath)) {
    path = path.substring(rootPath.length);
  }
  if (path.startsWith('/')) path = path.substring(1);
  return path.replaceAll('\\', '/');
}

List<UiLibraryHit> findUiLibraryHits(String source, {String path = ''}) {
  final masked = maskNonCode(source);
  if (masked.length != source.length) {
    throw StateError('Маска комментариев разъехалась с исходником: $path');
  }
  final lineStarts = <int>[0];
  for (var i = 0; i < source.length; i++) {
    if (source.codeUnitAt(i) == 10) lineStarts.add(i + 1);
  }
  int lineOfIndex(int index) {
    var low = 0;
    var high = lineStarts.length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (lineStarts[mid] <= index) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low + 1;
  }

  bool allowed(int index) {
    final line = lineOfIndex(index);
    final start = lineStarts[line - 1];
    final end = line < lineStarts.length ? lineStarts[line] - 1 : source.length;
    return source.substring(start, end).contains('ui-library-allow');
  }

  final found = <(int, String)>[];
  void add(RegExpMatch match, String token) {
    if (allowed(match.start)) return;
    found.add((match.start, token));
  }

  for (final match in _colors.allMatches(masked)) {
    final name = match.group(1)!;
    if (name == 'transparent') continue;
    add(match, 'Colors.$name');
  }
  for (final match in _hex.allMatches(masked)) {
    final hex = match.group(1)!;
    add(match, 'Color(0x${hex.substring(2).toUpperCase()})');
  }
  for (final match in _from.allMatches(masked)) {
    add(match, match.group(0)!);
  }
  found.sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (final hit in found)
      UiLibraryHit(path: path, line: lineOfIndex(hit.$1), token: hit.$2),
  ];
}

/// Комментарии и строки заменяет пробелами, переводы строк оставляет.
String maskNonCode(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      while (i < source.length && source[i] != '\n') {
        out.write(' ');
        i++;
      }
      continue;
    }
    if (source.startsWith('/*', i)) {
      out.write('  ');
      i += 2;
      while (i < source.length && !source.startsWith('*/', i)) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      if (i < source.length) {
        out.write('  ');
        i += 2;
      }
      continue;
    }
    if (_stringOpensAt(source, i)) {
      i = _consumeString(source, i, out);
      continue;
    }
    out.write(source[i]);
    i++;
  }
  return out.toString();
}

bool _stringOpensAt(String source, int i) {
  final raw = source[i] == 'r' &&
      i + 1 < source.length &&
      (source[i + 1] == "'" || source[i + 1] == '"') &&
      (i == 0 || !_isIdent(source[i - 1]));
  if (raw) return true;
  return source[i] == "'" || source[i] == '"';
}

bool _isIdent(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 48 && code <= 57) ||
      (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      char == '_';
}

int _consumeString(String source, int i, StringBuffer out) {
  var raw = false;
  if (source[i] == 'r') {
    raw = true;
    out.write(' ');
    i++;
  }
  final quote = source[i];
  final triple =
      i + 2 < source.length && source[i + 1] == quote && source[i + 2] == quote;
  final delim = triple ? 3 : 1;
  for (var k = 0; k < delim; k++) {
    out.write(' ');
    i++;
  }
  while (i < source.length) {
    if (!raw && source[i] == r'\') {
      out.write(' ');
      i++;
      if (i < source.length) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      continue;
    }
    if (delim == 3 &&
        i + 2 < source.length &&
        source[i] == quote &&
        source[i + 1] == quote &&
        source[i + 2] == quote) {
      out.write('   ');
      return i + 3;
    }
    if (delim == 1 && source[i] == quote) {
      out.write(' ');
      return i + 1;
    }
    out.write(source[i] == '\n' ? '\n' : ' ');
    i++;
  }
  return i;
}

Map<String, int> countHits(Iterable<UiLibraryHit> hits) {
  final counts = <String, int>{};
  for (final hit in hits) {
    counts.update(hit.key, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

String formatBaseline(Iterable<UiLibraryHit> hits) {
  final counts = countHits(hits);
  final keys = counts.keys.toList()..sort();
  final lines = <String>[
    '# Литералы цвета в client/lib, которые уже были до проверки.',
    '# Новый Colors.* или Color(0x…) роняет сборку: цвет клади в AppColors или GamePalette.',
    '# Строка: путь, токен, число вхождений.',
  ];
  for (final key in keys) {
    lines.add('$key\t${counts[key]}');
  }
  return lines.join('\n');
}

Map<String, int> loadBaseline(File file) {
  if (!file.existsSync()) {
    throw StateError(
        'Нет базы ${file.path}. Сначала: dart run tool/ui_library_guard.dart --write-baseline');
  }
  final counts = <String, int>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split('\t');
    if (parts.length != 3) {
      throw FormatException('Строка базы должна быть из трёх полей: $line');
    }
    final count = int.tryParse(parts[2]);
    if (count == null || count < 1) {
      throw FormatException('Число вхождений в базе битое: $line');
    }
    counts['${parts[0]}\t${parts[1]}'] = count;
  }
  return counts;
}

UiLibraryReport diffHits(List<UiLibraryHit> hits, Map<String, int> baseline) {
  final actual = countHits(hits);
  final byKey = <String, List<int>>{};
  for (final hit in hits) {
    byKey.putIfAbsent(hit.key, () => []).add(hit.line);
  }
  final added = <String>[];
  final removed = <String>[];
  final keys = {...actual.keys, ...baseline.keys}.toList()..sort();
  for (final key in keys) {
    final now = actual[key] ?? 0;
    final was = baseline[key] ?? 0;
    if (now == was) continue;
    final split = key.split('\t');
    final path = split[0];
    final token = split[1];
    if (now > was) {
      final lines = (byKey[key] ?? const <int>[]).toList()..sort();
      final shown = lines.skip(was).take(now - was);
      if (shown.isEmpty) {
        added.add('$path $token (+${now - was})');
      } else {
        for (final line in shown) {
          added.add('$path:$line $token');
        }
      }
    } else {
      removed.add('- $path $token (в коде $now, в базе $was)');
    }
  }
  return UiLibraryReport(added: added, removed: removed);
}
