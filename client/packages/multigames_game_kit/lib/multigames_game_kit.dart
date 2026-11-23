/// Библиотека игровых компонентов MultiGames.
///
/// Всё, из чего собирается стол любой игры: палитра, поверхность стола,
/// полёты фишек, рука, россыпь прикупа, подгонка под высоту. Компоненты не
/// знают про Riverpod, локализацию и сеть — их связывает с приложением общий
/// хром партии (`lib/games/framework/`).
library;

export 'layout/game_table_fit.dart';
export 'layout/scatter_layout.dart';
export 'motion/game_flight.dart';
export 'motion/game_motion.dart';
export 'theme/game_palette.dart';
export 'theme/turn_timer_style.dart';
export 'widgets/game_hand_strip.dart';
export 'widgets/game_table_surface.dart';
