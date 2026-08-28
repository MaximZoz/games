/// Назад из поля «О себе»: остаёмся в редактировании.
/// Назад из остальной формы: выход в просмотр профиля.
enum ProfileEditBackAction { stayInEditor, exitEditor }

ProfileEditBackAction profileEditBackAction({required bool aboutFocused}) {
  return aboutFocused
      ? ProfileEditBackAction.stayInEditor
      : ProfileEditBackAction.exitEditor;
}

/// Тап по пустому в форме: если фокус в «О себе» — только снять фокус.
bool shouldUnfocusAboutOnEmptyTap({required bool aboutFocused}) => aboutFocused;
