import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/scan.dart';

PluginBase createPlugin() => _UiLibraryPlugin();

class _UiLibraryPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        const UseUiLibraryRule(),
      ];
}

class UseUiLibraryRule extends DartLintRule {
  const UseUiLibraryRule() : super(code: _code);

  static const _code = LintCode(
    name: uiLibraryLintName,
    problemMessage: '{0}',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final relative = clientLibRelative(resolver.path);
    if (relative == null || !isClientLibSource(relative)) return;
    final baselineFile = baselineFileNear(resolver.path);
    if (baselineFile == null) return;
    final source = resolver.source.contents.data;
    final hits = findUiLibraryHits(source, path: relative);
    for (final hit in hitsBeyondBaseline(hits, loadBaseline(baselineFile))) {
      reporter.atOffset(
        errorCode: _code,
        offset: hit.offset,
        length: hit.length,
        arguments: [hit.problem],
      );
    }
  }
}
