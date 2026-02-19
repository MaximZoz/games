import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> savePickedImagePath(String userId, List<int> bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = io.Directory('${dir.path}/avatars');
    if (!await avatarDir.exists()) await avatarDir.create(recursive: true);
    final path = '${avatarDir.path}/$userId.jpg';
    final file = io.File(path);
    await file.writeAsBytes(bytes);
    return path;
  } catch (_) {
    return null;
  }
}

ImageProvider? imageProviderForAvatarPath(String path) {
  try {
    final file = io.File(path);
    if (file.existsSync()) return FileImage(file);
  } catch (_) {}
  return null;
}

bool get isIoAvailable => true;
