import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
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

/// Целевой размер файла после сжатия (очень компактно для чата).
const int chatImageTargetMaxBytes = 120 * 1024;

/// Жёсткий потолок — не отправляем больше.
const int chatImageHardMaxBytes = 200 * 1024;

const int _chatImageMaxSide = 960;

/// Сильное JPEG-сжатие: уменьшение стороны + лестница качества до целевого размера.
Uint8List compressChatImageBytes(Uint8List source) {
  final decoded = img.decodeImage(source);
  if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
    return source;
  }

  img.Image working = decoded;
  var maxSide = _chatImageMaxSide;
  Uint8List? best;

  for (var shrinkStep = 0; shrinkStep < 4; shrinkStep++) {
    final longest = math.max(working.width, working.height);
    if (longest > maxSide) {
      final scale = maxSide / longest;
      working = img.copyResize(
        decoded,
        width: math.max(1, (decoded.width * scale).round()),
        height: math.max(1, (decoded.height * scale).round()),
        interpolation: img.Interpolation.average,
      );
    } else if (shrinkStep == 0) {
      working = decoded;
    }

    for (final quality in const [58, 48, 40, 32, 26]) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(working, quality: quality),
      );
      if (best == null || encoded.lengthInBytes < best.lengthInBytes) {
        best = encoded;
      }
      if (encoded.lengthInBytes <= chatImageTargetMaxBytes) {
        return encoded;
      }
    }

    maxSide = (maxSide * 0.75).round().clamp(320, _chatImageMaxSide);
    final scale = maxSide / math.max(decoded.width, decoded.height);
    working = img.copyResize(
      decoded,
      width: math.max(1, (decoded.width * scale).round()),
      height: math.max(1, (decoded.height * scale).round()),
      interpolation: img.Interpolation.average,
    );
  }

  return best ?? source;
}

/// Сырые байты из галереи/камеры (без финального сжатия).
Future<Uint8List?> pickChatImageRawBytes(ImageSource source) async {
  if (kIsWeb && source == ImageSource.gallery) {
    final raw = await pickImageBytesWeb();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    // Предсжатие на нативе; финальное — compressChatImageBytes.
    maxWidth: 1280,
    maxHeight: 1280,
    imageQuality: 55,
  );
  if (file == null) return null;
  final raw = await file.readAsBytes();
  if (raw.isEmpty) return null;
  return raw;
}

/// Сжатие уже выбранных байтов в JPEG для отправки в чат.
PickedChatImage? compressRawChatImage(Uint8List raw) {
  if (raw.isEmpty) return null;
  final compressed = compressChatImageBytes(raw);
  if (compressed.isEmpty) return null;
  if (compressed.lengthInBytes > chatImageHardMaxBytes) {
    // Ещё один проход с меньшим лимитом стороны.
    final tighter = compressChatImageBytes(compressed);
    if (tighter.lengthInBytes > chatImageHardMaxBytes) {
      return null;
    }
    return PickedChatImage(
      bytes: tighter,
      mime: 'image/jpeg',
      base64: base64Encode(tighter),
    );
  }
  return PickedChatImage(
    bytes: compressed,
    mime: 'image/jpeg',
    base64: base64Encode(compressed),
  );
}

/// Выбор фото для чата (камера / галерея) с агрессивным JPEG-сжатием.
Future<PickedChatImage?> pickAndCompressChatImage(ImageSource source) async {
  final raw = await pickChatImageRawBytes(source);
  if (raw == null) return null;
  return compressRawChatImage(raw);
}
