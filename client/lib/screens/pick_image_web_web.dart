// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_pick_completion.dart';

const _resumeGracePeriod = Duration(milliseconds: 700);
const _hardPickerTimeout = Duration(minutes: 3);

/// [capture] — `'user'` / `'environment'` открывает камеру напрямую
/// (без системного sheet «Медиатека / Снимок / Файл» на iOS).
/// `null` — обычный выбор файла/галереи.
Future<Uint8List?> pickImageBytesWeb({String? capture}) async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..style.display = 'none';
  if (capture != null && capture.isNotEmpty) {
    input.setAttribute('capture', capture);
  }
  final completion = ImagePickCompletion<Uint8List>(
    resumeGracePeriod: _resumeGracePeriod,
    hardTimeout: _hardPickerTimeout,
  );
  var wasHidden = false;

  void onCancel(html.Event _) => completion.cancel();

  void onFocus(html.Event _) => completion.resumed();

  void onVisibilityChange(html.Event _) {
    if (html.document.hidden == true) {
      wasHidden = true;
    } else if (wasHidden) {
      completion.resumed();
    }
  }

  void onTouchEnd(html.Event _) => completion.resumed();

  void onChange(html.Event _) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completion.cancel();
      return;
    }

    completion.selectionStarted();
    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      final result = reader.result;
      if (result is List<int>) {
        completion.complete(Uint8List.fromList(result));
      } else {
        completion.completeError(
          StateError('Browser returned an invalid image byte payload'),
        );
      }
    });
    reader.onError.first.then(
      (event) => completion.completeError(
        StateError('Browser failed to read the selected image'),
      ),
    );
    reader.readAsArrayBuffer(files.first);
  }

  input.addEventListener('change', onChange);
  input.addEventListener('cancel', onCancel);
  html.window.addEventListener('focus', onFocus);
  html.document.addEventListener('visibilitychange', onVisibilityChange);

  html.document.body?.append(input);
  input.click();

  // On iOS the source action sheet can be dismissed by tapping the page
  // without changing focus or visibility. Arm this fallback after the opening
  // tap has finished propagating so it cannot cancel its own picker.
  Timer.run(() {
    if (!completion.isCompleted) {
      html.window.addEventListener('touchend', onTouchEnd);
    }
  });

  try {
    return await completion.future;
  } finally {
    input.removeEventListener('change', onChange);
    input.removeEventListener('cancel', onCancel);
    html.window.removeEventListener('focus', onFocus);
    html.window.removeEventListener('touchend', onTouchEnd);
    html.document.removeEventListener(
      'visibilitychange',
      onVisibilityChange,
    );
    input.remove();
  }
}
