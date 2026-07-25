// На вебе — браузерный file picker, на остальных платформах — заглушка.
export 'pick_image_web_stub.dart'
    if (dart.library.html) 'pick_image_web_web.dart';
