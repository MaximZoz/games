import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:multigames_client/ui/widgets/avatar_crop_dialog.dart';

void main() {
  Uint8List jpegBytes(int width, int height, {int quality = 92}) {
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        image.setPixelRgba(
          x,
          y,
          (x * 255 / width).round(),
          (y * 255 / height).round(),
          ((x + y) * 128 / (width + height)).round(),
          255,
        );
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  test('compactAvatarBytesSync уменьшает кроп до 640px JPEG', () {
    final raw = jpegBytes(1800, 1800);
    expect(raw.lengthInBytes, greaterThan(avatarStorageLimitBytes));

    final compact = compactAvatarBytesSync(raw);
    expect(compact, isNotNull);
    expect(compact!.lengthInBytes, lessThanOrEqualTo(avatarStorageLimitBytes));
    expect(compact.lengthInBytes, lessThan(raw.lengthInBytes));

    final decoded = img.decodeImage(compact);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(avatarMaxSidePx));
    expect(decoded.height, lessThanOrEqualTo(avatarMaxSidePx));
    expect(mathMax(decoded.width, decoded.height), greaterThan(96));
  });

  test('compactAvatarBytesSync не увеличивает маленькое фото', () {
    final raw = jpegBytes(240, 180, quality: 80);
    final compact = compactAvatarBytesSync(raw);
    expect(compact, isNotNull);
    final decoded = img.decodeImage(compact!);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(240));
    expect(decoded.height, lessThanOrEqualTo(180));
  });

  test('buildCompactAvatarValue пишет base64 JPEG в лимите', () async {
    final raw = jpegBytes(960, 960);
    final value = await buildCompactAvatarValue(raw);
    expect(value, isNotNull);
    expect(value!.startsWith('base64,'), isTrue);
    expect(value.length, lessThan(avatarStorageLimitBytes * 2));
  });
}

int mathMax(int a, int b) => a > b ? a : b;
