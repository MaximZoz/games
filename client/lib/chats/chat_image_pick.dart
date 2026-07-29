import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:multigames_client/screens/pick_image_web.dart';

class PickedChatImage {
  const PickedChatImage({
    required this.bytes,
    required this.mime,
    required this.base64,
  });

  final Uint8List bytes;
  final String mime;
  final String base64;
}

/// Выбор фото для чата (камера / галерея) с лёгким сжатием через image_picker.
Future<PickedChatImage?> pickAndCompressChatImage(ImageSource source) async {
  Uint8List? raw;
  if (kIsWeb && source == ImageSource.gallery) {
    raw = await pickImageBytesWeb();
  } else {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (file == null) return null;
    raw = await file.readAsBytes();
  }
  if (raw == null || raw.isEmpty) return null;

  return PickedChatImage(
    bytes: raw,
    mime: 'image/jpeg',
    base64: base64Encode(raw),
  );
}
