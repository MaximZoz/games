import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/profile_edit_back.dart';

void main() {
  test('назад из развёрнутого поля остаётся в редактировании', () {
    expect(
      profileEditBackAction(fieldFocused: true),
      ProfileEditBackAction.stayInEditor,
    );
  });

  test('назад из формы выходит в профиль', () {
    expect(
      profileEditBackAction(fieldFocused: false),
      ProfileEditBackAction.exitEditor,
    );
  });

  test('тап по пустому сворачивает поле, не закрывает редактор', () {
    expect(shouldUnfocusFieldOnEmptyTap(fieldFocused: true), isTrue);
    expect(shouldUnfocusFieldOnEmptyTap(fieldFocused: false), isFalse);
  });

  test('web blur не сбрасывает «поле открыто»', () {
    expect(shouldClearFieldOpenOnFocusLost(), isFalse);
  });

  test('раскладка зависит от тапа по полю, не от клавиатуры', () {
    expect(
      profileEditCompactLayout(
        phoneLandscape: true,
        fieldTypingActive: false,
      ),
      ProfileEditCompactLayout.landscapeColumns,
    );
    expect(
      profileEditCompactLayout(
        phoneLandscape: true,
        fieldTypingActive: true,
      ),
      ProfileEditCompactLayout.singleField,
    );
    expect(
      profileEditCompactLayout(
        phoneLandscape: false,
        fieldTypingActive: true,
      ),
      ProfileEditCompactLayout.singleField,
    );
    expect(
      profileEditCompactLayout(
        phoneLandscape: false,
        fieldTypingActive: false,
      ),
      ProfileEditCompactLayout.portraitForm,
    );
  });

  test('имя, возраст и «о себе» считаются активным полем', () {
    expect(profileEditFieldActive(ProfileEditField.none), isFalse);
    expect(profileEditFieldActive(ProfileEditField.name), isTrue);
    expect(profileEditFieldActive(ProfileEditField.age), isTrue);
    expect(profileEditFieldActive(ProfileEditField.about), isTrue);
  });

  test('полоска ввода однострочная в портрете и альбоме, без expands', () {
    expect(profileEditUseInputStrip(fieldTypingActive: true), isTrue);
    expect(profileEditUseInputStrip(fieldTypingActive: false), isFalse);
    expect(profileEditFieldExpands(phoneLandscape: true), isFalse);
    expect(profileEditFieldExpands(phoneLandscape: false), isFalse);
    expect(profileEditStripMaxLines(), 1);
  });

  test('оболочка на профиле не ресайзится, на остальных экранах — да', () {
    expect(profileEditShellResizeToAvoidInset(onProfile: true), isFalse);
    expect(profileEditShellResizeToAvoidInset(onProfile: false), isTrue);
  });

  test('форма остаётся видна вместе с полоской ввода в любой ориентации', () {
    expect(
      profileEditKeepFormWithStrip(
        phoneLandscape: false,
        fieldTypingActive: true,
      ),
      isTrue,
    );
    // В альбоме от формы остаётся узкая полоса, но экран не пустой.
    expect(
      profileEditKeepFormWithStrip(
        phoneLandscape: true,
        fieldTypingActive: true,
      ),
      isTrue,
    );
    // Поле закрыто — обычная форма, полоски нет.
    expect(
      profileEditKeepFormWithStrip(
        phoneLandscape: false,
        fieldTypingActive: false,
      ),
      isFalse,
    );
  });

  test('компактный хром чатов и друзей — только с клавиатурой', () {
    expect(
      inputHideChrome(phoneLandscape: true, keyboardInset: 220),
      isTrue,
    );
    expect(
      inputHideChrome(phoneLandscape: true, keyboardInset: 0),
      isFalse,
    );
    expect(
      inputHideChrome(phoneLandscape: false, keyboardInset: 300),
      isFalse,
    );
  });
}
