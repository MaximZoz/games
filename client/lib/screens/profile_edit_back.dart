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

/// Компактной полоски ввода без клавиатуры быть не должно: если клавиатура
/// была открыта и её убрали (тап в пустое место, кнопка «свернуть»), поле
/// закрывается и возвращается обычная форма. Пока клавиатура ещё не успела
/// выехать (`keyboardWasOpen == false`), полоску не трогаем — иначе она
/// закроется сразу после тапа, а на десктопе не откроется вовсе.
bool profileEditShouldLeaveFieldOnKeyboardHidden({
  required bool fieldTypingActive,
  required bool keyboardWasOpen,
  required bool keyboardOpen,
}) =>
    fieldTypingActive && keyboardWasOpen && !keyboardOpen;

/// Форма видна и при открытом поле: полоска ввода прижата к клавиатуре снизу,
/// а над ней остаётся форма. В альбоме от формы остаётся узкая полоса, но это
/// лучше пустого экрана, а текст стоит у клавиатуры, а не у верхнего края.
bool profileEditKeepFormWithStrip({
  required bool phoneLandscape,
  required bool fieldTypingActive,
}) =>
    fieldTypingActive;

/// На профиле внешний Scaffold не должен resize: вместе с viewInsets
/// на iOS получается пустой блок над клавиатурой.
///
/// Друзьям и чатам resize нужен: Scaffold снимает viewInsets у вложенных
/// экранов, иначе чат вычитает клавиатуру дважды и композер уезжает вверх.
bool profileEditShellResizeToAvoidInset({required bool onProfile}) =>
    !onProfile;

/// Компактный режим только при реально открытой клавиатуре: по одному фокусу
/// полоска висела бы без клавиатуры (на iOS фокус есть, клавиатуры нет).
bool inputHideChrome({
  required bool phoneLandscape,
  required double keyboardInset,
}) =>
    phoneLandscape && keyboardInset >= 80;
