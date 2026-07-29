{{flutter_js}}
{{flutter_build_config}}

// Без Flutter service worker: иначе flutter_service_worker.js перехватывает
// scope у push-sw.js и на activate снимает регистрацию — Web Push на iOS PWA
// перестаёт доставляться после включения чекбокса.
_flutter.loader.load();
