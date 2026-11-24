import 'dart:io';

import 'package:multigames_ui_lint/scan.dart';

export 'package:multigames_ui_lint/scan.dart';

void main(List<String> args) {
  final root = findClientRoot();
  final hits = scanClientLib(root);
  final baselineFile = File('${root.path}/$baselineName');
  if (args.contains('--write-baseline')) {
    baselineFile.writeAsStringSync('${formatBaseline(hits)}\n');
    stdout.writeln(
      'Записал $baselineName (${countHits(hits).length} записей).',
    );
    return;
  }
  final report = diffHits(hits, loadBaseline(baselineFile));
  if (!report.isClean) {
    stdout.writeln(report.format());
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
