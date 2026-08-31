import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/screens/friends_screen.dart';

void main() {
  group('friendsListEmptyText', () {
    const emptyList = 'У вас пока нет друзей';
    const nothingFound = 'Ничего не найдено';

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

    test('при поиске показывает «ничего не найдено»', () {
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
}
