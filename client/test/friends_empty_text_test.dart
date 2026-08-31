import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/friends_screen.dart';

void main() {
  group('friendsListEmptyText', () {
    const emptyList = 'У вас пока нет друзей';
    const nothingFound = 'Нет друзей, удовлетворяющих поиску';

    test('без запроса показывает пустой список', () {
      expect(
        friendsListEmptyText(
          query: '',
          emptyList: emptyList,
          nothingFound: nothingFound,
        ),
        emptyList,
      );
      expect(
        friendsListEmptyText(
          query: '   ',
          emptyList: emptyList,
          nothingFound: nothingFound,
        ),
        emptyList,
      );
    });

    test('при поиске показывает, что нет совпадений', () {
      expect(
        friendsListEmptyText(
          query: 'пр',
          emptyList: emptyList,
          nothingFound: nothingFound,
        ),
        nothingFound,
      );
      expect(
        friendsListEmptyText(
          query: '  ник  ',
          emptyList: emptyList,
          nothingFound: nothingFound,
        ),
        nothingFound,
      );
    });
  });

  group('friendsEmptyStatusPadding', () {
    test('в альбоме и при клавиатуре без отступа 80', () {
      expect(
        friendsEmptyStatusPadding(phoneLandscape: true, keyboardInset: 0).top,
        8,
      );
      expect(
        friendsEmptyStatusPadding(phoneLandscape: false, keyboardInset: 220)
            .top,
        8,
      );
    });

    test('в портрете без клавиатуры оставляет отступ', () {
      expect(
        friendsEmptyStatusPadding(phoneLandscape: false, keyboardInset: 0).top,
        80,
      );
    });
  });

  group('friendsHideTabsForKeyboard', () {
    test('прячет табы в альбоме над клавиатурой', () {
      expect(
        friendsHideTabsForKeyboard(landscape: true, keyboardInset: 200),
        isTrue,
      );
      expect(
        friendsHideTabsForKeyboard(landscape: true, keyboardInset: 0),
        isFalse,
      );
      expect(
        friendsHideTabsForKeyboard(landscape: false, keyboardInset: 280),
        isFalse,
      );
    });

    test('прячет табы в альбоме сразу при фокусе поиска', () {
      expect(
        friendsHideTabsForKeyboard(
          landscape: true,
          keyboardInset: 0,
          searchFieldOpen: true,
        ),
        isTrue,
      );
      expect(
        friendsHideTabsForKeyboard(
          landscape: false,
          keyboardInset: 0,
          searchFieldOpen: true,
        ),
        isFalse,
      );
    });
  });
}
