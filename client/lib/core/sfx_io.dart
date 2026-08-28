import 'package:audioplayers/audioplayers.dart';

bool get ioSfxSupported => true;

void ioSfxPlay(String assetPath, {double volume = 1}) {
  var path = assetPath;
  if (path.startsWith('assets/')) {
    path = path.substring('assets/'.length);
  }
  final player = AudioPlayer();
  player.setReleaseMode(ReleaseMode.release);
  player.onPlayerComplete.listen((_) => player.dispose());
  player.play(AssetSource(path), volume: volume.clamp(0, 1));
}
