import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_avatar_button.dart';

void main() {
  test('кнопка аватара всегда «Поменять аватар», не «Загрузить фото»', () {
    expect(
      profileAvatarActionLabel(
        processing: false,
        processingLabel: 'Готовим фото…',
        changeLabel: 'Поменять аватар',
      ),
      'Поменять аватар',
    );
  });

  test('во время обработки — статус, не «Загрузить фото»', () {
    expect(
      profileAvatarActionLabel(
        processing: true,
        processingLabel: 'Готовим фото…',
        changeLabel: 'Поменять аватар',
      ),
      'Готовим фото…',
    );
  });
}
