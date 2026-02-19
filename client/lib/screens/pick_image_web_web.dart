import 'dart:typed_data';

import 'package:image_picker_web/image_picker_web.dart';

Future<Uint8List?> pickImageBytesWeb() async =>
    await ImagePickerWeb.getImageAsBytes();
