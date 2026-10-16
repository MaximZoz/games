import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/friends/friends_repository.dart';
import 'package:multigames_client/screens/friends_screen.dart';
import 'package:multigames_client/ui/app_theme.dart';
import 'package:multigames_client/ui/responsive.dart';

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

  group('friendsDesktopGridLayout', () {
    test('на десктопе карточки поиска того же размера, что у друзей', () {
      final layout = friendsDesktopGridLayout(
        viewportWidth: 1400,
        phoneLandscape: false,
        tablet: false,
      );
      expect(layout.crossAxisCount, 3);
      expect(layout.contentWidth, friendsDesktopMaxContentWidth);
      expect(layout.itemWidth, lessThanOrEqualTo(320));
      expect(layout.itemWidth, greaterThan(280));
    });

    test('на планшете не больше трёх колонок', () {
      final layout = friendsDesktopGridLayout(
        viewportWidth: 900,
        phoneLandscape: false,
        tablet: true,
      );
      expect(layout.crossAxisCount, inInclusiveRange(1, 3));
      expect(layout.itemWidth, lessThan(400));
    });
  });

  group('friendsLoaderIsVisible', () {
    const viewport = Size(1280, 800);

    test('лоадер внизу видимой области — грузим следующую страницу', () {
      expect(
        friendsLoaderIsVisible(
          loaderGlobalRect: const Rect.fromLTWH(600, 720, 22, 22),
          viewportSize: viewport,
        ),
        isTrue,
      );
      expect(
        friendsShouldLoadNextPage(
          hasMore: true,
          loading: false,
          loaderVisible: true,
        ),
        isTrue,
      );
    });

    test('лоадер ниже экрана — не грузим', () {
      expect(
        friendsLoaderIsVisible(
          loaderGlobalRect: const Rect.fromLTWH(600, 920, 22, 22),
          viewportSize: viewport,
        ),
        isFalse,
      );
      expect(
        friendsShouldLoadNextPage(
          hasMore: true,
          loading: false,
          loaderVisible: false,
        ),
        isFalse,
      );
    });

    test('пока уже грузим — повторно не запускаем', () {
      expect(
        friendsShouldLoadNextPage(
          hasMore: true,
          loading: true,
          loaderVisible: true,
        ),
        isFalse,
      );
    });
  });

  group('friendsFindTabCount', () {
    test('пока опрос не пришёл, берёт число из списка друзей', () {
      expect(friendsFindTabCount(live: null, snapshot: 122), 122);
      expect(friendsFindTabCount(live: 130, snapshot: 122), 130);
    });

    test('без обоих источников бейджа нет', () {
      expect(friendsFindTabCount(live: null, snapshot: null), isNull);
    });
  });

  group('FriendsSnapshot.usersCount', () {
    test('читает users_count из того же ответа, что и друзья', () {
      final snapshot = FriendsSnapshot.fromJson({
        'friends': [],
        'incoming': [],
        'outgoing': [],
        'users_count': 122,
      });
      expect(snapshot.usersCount, 122);
    });

    test('старый ответ без поля не подставляет ноль', () {
      final snapshot = FriendsSnapshot.fromJson({
        'friends': [],
        'incoming': [],
        'outgoing': [],
      });
      expect(snapshot.usersCount, isNull);
    });
  });

  group('friendsUsePackedTabs', () {
    test('на десктопе и в альбоме вкладки собраны вместе', () {
      expect(
        friendsUsePackedTabs(width: 1280, phoneLandscape: false),
        isTrue,
      );
      expect(
        friendsUsePackedTabs(
          width: Breakpoints.mobile,
          phoneLandscape: false,
        ),
        isTrue,
      );
      expect(
        friendsUsePackedTabs(width: 740, phoneLandscape: true),
        isTrue,
      );
    });

    test('в портрете телефона вкладки делят ширину', () {
      expect(
        friendsUsePackedTabs(width: 390, phoneLandscape: false),
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
