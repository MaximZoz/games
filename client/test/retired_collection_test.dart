import 'package:flutter_test/flutter_test.dart';
import 'package:multigames_client/shop/collection_widgets.dart';

void main() {
  test('фейерверк снят с коллекции «Праздник»', () {
    expect(isRetiredCollectionItem('coll_fireworks'), isTrue);
    expect(isRetiredCollectionItem('coll_gift'), isFalse);
    expect(isRetiredCollectionItem('coll_party'), isFalse);
  });
}
