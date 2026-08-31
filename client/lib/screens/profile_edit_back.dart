import 'package:flutter/painting.dart';

/// Какое поле сейчас развёрнуто на весь экран редактора.
enum ProfileEditField { none, name, age, about }

bool profileEditFieldActive(ProfileEditField field) =>
    field != ProfileEditField.none;

/// Назад из развёрнутого поля: остаёмся в редактировании.
/// Назад из остальной формы: выход в просмотр профиля.
enum ProfileEditBackAction { stayInEditor, exitEditor }

ProfileEditBackAction profileEditBackAction({required bool fieldFocused}) {
  return fieldFocused
      ? ProfileEditBackAction.stayInEditor
      : ProfileEditBackAction.exitEditor;
}

/// Тап по пустому в форме: если поле развёрнуто — только свернуть.
bool shouldUnfocusFieldOnEmptyTap({required bool fieldFocused}) => fieldFocused;

/// Web Back сначала blur'ит TextField. Флаг «поле открыто» не сбрасываем
/// по потере фокуса — иначе PopScope выходит в просмотр профиля.
bool shouldClearFieldOpenOnFocusLost() => false;

/// Раскладка компактного редактора. Не зависит от [viewInsets]:
/// переключение Row/Column по клавиатуре сбрасывает фокус (фликер на iPhone).
enum ProfileEditCompactLayout { portraitForm, landscapeColumns, singleField }

ProfileEditCompactLayout profileEditCompactLayout({
  required bool phoneLandscape,
  required bool fieldTypingActive,
}) {
  if (fieldTypingActive) return ProfileEditCompactLayout.singleField;
  if (phoneLandscape) return ProfileEditCompactLayout.landscapeColumns;
  return ProfileEditCompactLayout.portraitForm;
}

/// Полоска ввода при открытом поле — и в портрете, и в альбоме.
/// `expands` / multiline включает Android extract UI: клавиатура есть,
/// а текста не видно.
bool profileEditUseInputStrip({required bool fieldTypingActive}) =>
    fieldTypingActive;

/// Разворачивать TextField на всю высоту нельзя: extract UI съедает текст.
bool profileEditFieldExpands({required bool phoneLandscape}) => false;

/// Всегда 1 строка, иначе IME уходит в fullscreen extract.
int profileEditStripMaxLines() => 1;

/// В альбоме клавиатура занимает почти весь экран — полоска сверху
/// (единственная видимая щель). В портрете — над клавиатурой снизу.
Alignment profileEditStripAlignment({required bool phoneLandscape}) {
  return phoneLandscape ? Alignment.topCenter : Alignment.bottomCenter;
}

/// На профиле внешний Scaffold не должен resize: вместе с viewInsets
/// на iOS получается пустой блок над клавиатурой.
bool profileEditShellResizeToAvoidInset({required bool onProfile}) =>
    !onProfile;
