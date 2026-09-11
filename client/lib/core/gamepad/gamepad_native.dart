import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:multigames_client/core/gamepad/gamepad_action.dart';

const androidGamepadChannel = MethodChannel('zozu/gamepad');

/// Список HID-геймпадов на Android. На вебе и других ОС — пусто.
Future<List<GamepadDevice>> listNativeGamepads() async {
  if (kIsWeb) return const [];
  if (defaultTargetPlatform != TargetPlatform.android) return const [];
  try {
    final raw = await androidGamepadChannel.invokeMethod<List<dynamic>>(
      'listDevices',
    );
    if (raw == null) return const [];
    return [
      for (final row in raw)
        if (row is Map)
          GamepadDevice(
            id: '${row['id'] ?? ''}',
            name: '${row['name'] ?? 'Gamepad'}',
            index: (row['index'] as num?)?.toInt() ?? 0,
          ),
    ].where((d) => d.id.isNotEmpty).toList(growable: false);
  } catch (_) {
    return const [];
  }
}
