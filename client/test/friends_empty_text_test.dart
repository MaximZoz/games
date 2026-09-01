import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/friends_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';

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
    test('прячет табы только с открытой клавиатурой', () {
      expect(
        friendsHideTabsForKeyboard(landscape: true, keyboardInset: 200),
        isTrue,
      );
      expect(
        friendsHideTabsForKeyboard(landscape: false, keyboardInset: 280),
        isTrue,
      );
    });

    test('без клавиатуры табы остаются', () {
      expect(
        friendsHideTabsForKeyboard(landscape: true, keyboardInset: 0),
        isFalse,
      );
      expect(
        friendsHideTabsForKeyboard(landscape: false, keyboardInset: 0),
        isFalse,
      );
    });
  });

  group('friendsTabCountColor', () {
    test('друзья — акцент, поиск — зелёный, входящие — красный', () {
      expect(
        friendsTabCountColor(incoming: false, findFriend: false, count: 3),
        AppColors.accentStart,
      );
      expect(
        friendsTabCountColor(incoming: false, findFriend: true, count: 108),
        Colors.green.shade700,
      );
      expect(
        friendsTabCountColor(incoming: true, findFriend: false, count: 2),
        Colors.red.shade600,
      );
      expect(
        friendsTabCountColor(incoming: true, findFriend: false, count: 0),
        AppColors.accentStart,
      );
    });
  });
}
