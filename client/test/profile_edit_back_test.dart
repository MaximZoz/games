import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_edit_back.dart';

void main() {
  test('назад из «О себе» остаётся в редактировании', () {
    expect(
      profileEditBackAction(aboutFocused: true),
      ProfileEditBackAction.stayInEditor,
    );
  });

  test('назад из формы выходит в профиль', () {
    expect(
      profileEditBackAction(aboutFocused: false),
      ProfileEditBackAction.exitEditor,
    );
  });

  test('тап по пустому снимает фокус «О себе», не закрывает редактор', () {
    expect(shouldUnfocusAboutOnEmptyTap(aboutFocused: true), isTrue);
    expect(shouldUnfocusAboutOnEmptyTap(aboutFocused: false), isFalse);
  });

  test('web blur не сбрасывает «О себе открыто»', () {
    expect(shouldClearAboutOpenOnFocusLost(), isFalse);
  });
}
