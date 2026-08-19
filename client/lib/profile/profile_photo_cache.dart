import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final profilePhotoBytesCacheProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

void clearProfilePhotoCachesFromRef(Ref ref) {
  ref.read(profilePhotoBytesCacheProvider.notifier).state = {};
}

void removeProfilePhotoFromCache(WidgetRef ref, String photoId) {
  if (photoId.isEmpty) return;
  ref.read(profilePhotoBytesCacheProvider.notifier).update((m) {
    final next = Map<String, Uint8List>.from(m);
    next.remove(photoId);
    return next;
  });
}
