import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AAB для Play Internal собирается с targetSdk 36', () {
    final file = File('android/app/build.gradle.kts');
    expect(file.existsSync(), isTrue);
    expect(
      file.readAsStringSync().contains(RegExp(r'targetSdk\s*=\s*36')),
      isTrue,
      reason: 'Play с 31.08.2026 отклоняет AAB с targetSdk < 36',
    );
  });
}
