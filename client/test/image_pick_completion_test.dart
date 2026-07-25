import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/image_pick_completion.dart';

void main() {
  const gracePeriod = Duration(milliseconds: 20);
  const hardTimeout = Duration(milliseconds: 80);

  ImagePickCompletion<Uint8List> createCompletion() {
    return ImagePickCompletion<Uint8List>(
      resumeGracePeriod: gracePeriod,
      hardTimeout: hardTimeout,
    );
  }

  test('cancel event completes with null', () async {
    final completion = createCompletion();

    completion.cancel();

    expect(await completion.future, isNull);
  });

  test('focus or visibility resume completes after grace period', () async {
    final completion = createCompletion();

    completion.resumed();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(completion.isCompleted, isFalse);

    expect(await completion.future, isNull);
  });

  test('selection wins a race with a resume cancellation', () async {
    final completion = createCompletion();
    final bytes = Uint8List.fromList(<int>[1, 2, 3]);

    completion.resumed();
    completion.selectionStarted();
    await Future<void>.delayed(gracePeriod);
    expect(completion.isCompleted, isFalse);
    completion.complete(bytes);

    expect(await completion.future, same(bytes));
  });

  test('hard timeout completes when the browser emits no events', () async {
    final completion = createCompletion();

    expect(await completion.future, isNull);
    expect(completion.isCompleted, isTrue);
  });

  test('hard timeout also releases a stalled file read', () async {
    final completion = createCompletion();

    completion.selectionStarted();

    expect(await completion.future, isNull);
  });
}
