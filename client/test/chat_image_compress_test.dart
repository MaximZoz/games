import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:multigames_client/chats/chat_image_pick.dart';

void main() {
  test('compressChatImageBytes сильно уменьшает большой JPEG', () {
    final big = img.Image(width: 2400, height: 1800);
    for (var y = 0; y < big.height; y++) {
      for (var x = 0; x < big.width; x++) {
        big.setPixelRgba(
          x,
          y,
          (x * 37) % 255,
          (y * 53) % 255,
          ((x + y) * 17) % 255,
          255,
        );
      }
    }
    final raw = Uint8List.fromList(img.encodeJpg(big, quality: 92));
    expect(raw.lengthInBytes, greaterThan(200 * 1024));

    final compressed = compressChatImageBytes(raw);
    expect(compressed.lengthInBytes, lessThanOrEqualTo(chatImageHardMaxBytes));
    expect(compressed.lengthInBytes, lessThan(raw.lengthInBytes));

    final decoded = img.decodeImage(compressed);
    expect(decoded, isNotNull);
    expect(mathMax(decoded!.width, decoded.height), lessThanOrEqualTo(960));
  });
}

int mathMax(int a, int b) => a > b ? a : b;
