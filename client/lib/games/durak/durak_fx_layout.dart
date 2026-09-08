import 'dart:math' as math;
import 'dart:ui' show Size;

/// Как показать итог партии дурака.
enum DurakFinishedChrome {
  /// Партия идёт — стол и веер на месте.
  playing,

  /// Портрет: статус и кнопки реванша столбиком над столом.
  stacked,

  /// Телефон в альбоме: статус и кнопки в ряд, веер и стол скрыты —
  /// иначе колонка съедает ~300 px высоты и остатки FX торчат по углам.
  landscapeRow,
}

DurakFinishedChrome durakFinishedChrome({
  required bool isOver,
  required bool phoneLandscape,
}) {
  if (!isOver) return DurakFinishedChrome.playing;
  if (phoneLandscape) return DurakFinishedChrome.landscapeRow;
  return DurakFinishedChrome.stacked;
}

/// В альбоме твин короче: там перестановки заметнее и 380 ms уже «плывут».
///
/// Раньше в альбоме твина не было вовсе, и веер схлопывался рывком. Кадры
/// после поворота сбрасываются ключом [durakLayoutTweenKey], поэтому старая
/// геометрия больше не тянется в новый кадр.
Duration durakLayoutTweenDuration({required bool compact}) => Duration(
      milliseconds: compact ? 220 : 340,
    );

/// Ключ твинов раскладки: меняется при повороте/смене размера окна.
///
/// Смена ключа пересоздаёт [TweenAnimationBuilder], и новый размер встаёт
/// сразу — без проезда из геометрии прошлой ориентации.
String durakLayoutTweenKey(Size screen) {
  final w = (screen.width / 40).round();
  final h = (screen.height / 40).round();
  return '$w x $h';
}

/// Масштаб карты веера от числа карт — непрерывная кривая.
///
/// Ступеньки «7 → 8 карт» роняли размер сразу на 10%, и веер схлопывался
/// рывком. Между узлами интерполируем, поэтому каждая новая карта сжимает
/// веер чуть-чуть.
double durakFanScaleFor(int n) => _interpolate(n, _fanScaleNodes);

/// Минимальный шаг между картами в долях ширины карты — тоже непрерывно.
double durakFanMinSpacingFrac(int n) => _interpolate(n, _fanSpacingNodes);

const List<(int, double)> _fanScaleNodes = [
  (6, 1.0),
  (9, 0.90),
  (12, 0.80),
  (16, 0.70),
  (20, 0.60),
  (26, 0.50),
  (34, 0.40),
];

const List<(int, double)> _fanSpacingNodes = [
  (5, 0.42),
  (7, 0.32),
  (9, 0.22),
  (12, 0.16),
  (15, 0.12),
  (19, 0.10),
  (23, 0.08),
  (29, 0.06),
  (34, 0.05),
];

double _interpolate(int n, List<(int, double)> nodes) {
  if (n <= nodes.first.$1) return nodes.first.$2;
  if (n >= nodes.last.$1) return nodes.last.$2;
  for (var i = 0; i < nodes.length - 1; i++) {
    final (x0, y0) = nodes[i];
    final (x1, y1) = nodes[i + 1];
    if (n <= x1) {
      final t = (n - x0) / (x1 - x0);
      return y0 + (y1 - y0) * t;
    }
  }
  return nodes.last.$2;
}

/// Низ кнопки «Бито»/«Взять» от низа стола. В альбоме — целиком над веером.
double durakActionButtonBottom({
  required bool compact,
  required double seatLift,
  required double fanCardH,
}) {
  if (!compact) return -seatLift + fanCardH + 10;
  // Запас больше высоты слота/свечения: иначе «Взять» садится на середину карт.
  return seatLift + fanCardH + 36;
}

/// Горизонталь кнопки: 0 — центр, 1 — правый край.
/// В альбоме правее, чтобы не накрывать карты стола.
double durakActionButtonAlignX({required bool compact}) =>
    compact ? 0.62 : 0.0;

/// Сколько высоты отдать столу под слот кнопки в альбоме.
double durakBoardBottomReserve({
  required bool compact,
  required double actionBtnBottom,
  required double actionSlotH,
  required double fanZoneH,
}) {
  if (!compact) return 0;
  final extra = actionBtnBottom + actionSlotH + 10 - fanZoneH;
  return extra < 0 ? 0.0 : extra;
}

/// В альбоме колода и бита не выглядывают за край — иначе обрезок и «призраки».
bool durakPilesPeekOffEdge({required bool compact}) => !compact;

/// Отступ колоды/биты от края доски.
double durakPileEdgeInset({required bool compact}) => compact ? 10.0 : 2.0;

/// Ширина колоды: в альбоме стопка в кадре, козырь торчит вправо как в портрете.
double durakDeckPileWidth({
  required Size cardSize,
  required bool peekOffEdge,
}) {
  if (peekOffEdge) {
    return cardSize.width * 0.55 + cardSize.height * 0.82;
  }
  return cardSize.width * 1.05 + cardSize.height * 0.70;
}

/// Левый край повёрнутого козыря внутри колоды.
double durakDeckTrumpLeft({
  required Size cardSize,
  required bool peekOffEdge,
}) {
  if (peekOffEdge) return cardSize.width * 0.22;
  return cardSize.width * 0.70;
}

/// Сколько козыря торчит справа от стопки рубашек.
double durakDeckTrumpVisibleWidth({
  required Size cardSize,
  required bool peekOffEdge,
}) {
  final stackRight = peekOffEdge
      ? cardSize.width * (1 - 0.48)
      : cardSize.width;
  final trumpRight = durakDeckTrumpLeft(
        cardSize: cardSize,
        peekOffEdge: peekOffEdge,
      ) +
      cardSize.width / 2 +
      cardSize.height / 2;
  final visible = trumpRight - stackRight;
  return visible < 0 ? 0.0 : visible;
}

/// Коридор слева под колоду + козырь.
double durakBoardLeftReserve({
  required bool compact,
  required Size cardSize,
}) {
  final deckW = durakDeckPileWidth(
    cardSize: cardSize,
    peekOffEdge: !compact,
  );
  return deckW + (compact ? 18.0 : 14.0);
}

/// Коридор справа под биту целиком в кадре (поворот карты + inset).
///
/// Пустая бита не занимает слот — иначе в альбоме справа дыра, как «Бита 0».
double durakBoardRightReserve({
  required bool compact,
  required Size cardSize,
  int bitoCount = 1,
}) {
  if (bitoCount <= 0) {
    return compact ? 16.0 : 10.0;
  }
  if (!compact) {
    return math.max(90.0, cardSize.width * 0.70) + 12;
  }
  return math.max(96.0, cardSize.width * 1.70) + 18;
}

/// Минимальная высота плитки веера соперника.
///
/// В альбоме 24 px сливались в «иконку» — рубашки должны читаться как карты.
double durakOpponentFanTileMinH({required bool compact}) =>
    compact ? 48.0 : 32.0;

/// Минимальная ширина плитки веера соперника.
double durakOpponentFanTileMinW({required bool compact}) =>
    compact ? 34.0 : 22.0;

/// Доля ширины экрана под веер соперника.
double durakOpponentFanMaxWidthFrac({required bool compact}) =>
    compact ? 0.56 : 1 / 3;

/// Базовый масштаб плитки от карты стола.
double durakOpponentFanBaseScale({required bool compact}) =>
    compact ? 0.82 : 0.44;

double durakOpponentFanTileScale({
  required bool compact,
  required int shown,
}) {
  final base = durakOpponentFanBaseScale(compact: compact);
  if (shown > 16) return compact ? 0.46 : 0.30;
  if (shown > 12) return compact ? 0.50 : 0.34;
  if (shown > 9) return compact ? 0.54 : 0.38;
  if (shown > 6) return compact ? 0.58 : 0.41;
  return base;
}

double durakOpponentFanMinStepFrac(int shown) {
  if (shown > 16) return 0.18;
  if (shown > 12) return 0.22;
  if (shown > 9) return 0.28;
  if (shown > 6) return 0.36;
  if (shown > 4) return 0.46;
  return 0.58;
}

/// Сколько рубашек рисуем в веере соперника.
///
/// [hidden] — добор из колоды и/или вскрытие козыря: эти карты ещё в полёте.
/// Пока все карты скрыты, веер пустой — иначе сначала вспыхивает вся рука,
/// а потом уже летит добор. Зависший FX снимает pending через snap.
int durakOpponentFanShownCount({
  required int serverCount,
  required int hidden,
}) {
  final n = serverCount < 0 ? 0 : serverCount;
  final hide = hidden < 0 ? 0 : hidden;
  final visible = n - hide;
  if (visible <= 0) return 0;
  if (visible > 20) return 20;
  return visible;
}

/// Snap к серверу обязан открыть то, что прятал незавершённый FX.
void durakSnapRevealHiddenFx(Map<int, int> oppDealPending) {
  oppDealPending.clear();
}

/// Геометрия веера соперника: плитка, шаг, дуга, фиксированный слот по высоте.
class DurakOpponentFanGeometry {
  const DurakOpponentFanGeometry({
    required this.tile,
    required this.step,
    required this.totalW,
    required this.arcH,
    required this.reserveH,
    required this.shown,
  });

  final Size tile;
  final double step;
  final double totalW;
  final double arcH;
  final double reserveH;
  final int shown;
}

DurakOpponentFanGeometry durakOpponentFanGeometry({
  required Size cardSize,
  required int shown,
  required double maxWidth,
  required bool compact,
}) {
  final minH = durakOpponentFanTileMinH(compact: compact);
  final minW = durakOpponentFanTileMinW(compact: compact);
  final maxTileW = compact ? 58.0 : 52.0;
  final maxTileH = compact ? 84.0 : 76.0;
  final tileScale = durakOpponentFanTileScale(compact: compact, shown: shown);
  var tile = Size(
    (cardSize.width * tileScale).clamp(minW, maxTileW),
    (cardSize.height * tileScale).clamp(minH, maxTileH),
  );
  final reserveTileH =
      (cardSize.height * durakOpponentFanBaseScale(compact: compact))
          .clamp(minH, maxTileH);
  final reserveH = reserveTileH + reserveTileH * 0.28 + 8;

  if (shown <= 0) {
    return DurakOpponentFanGeometry(
      tile: tile,
      step: 0,
      totalW: tile.width,
      arcH: 0,
      reserveH: reserveH,
      shown: 0,
    );
  }

  var step = shown <= 1 ? 0.0 : tile.width * durakOpponentFanMinStepFrac(shown);
  var totalW = tile.width + step * math.max(shown - 1, 0);
  if (shown > 1 && totalW > maxWidth) {
    for (var i = 0; i < 24 && totalW > maxWidth && tile.width > minW; i++) {
      final s = (maxWidth / totalW).clamp(0.50, 0.96);
      tile = Size(
        (tile.width * s).clamp(minW, tile.width),
        (tile.height * s).clamp(minH, tile.height),
      );
      step = tile.width * durakOpponentFanMinStepFrac(shown);
      totalW = tile.width + step * (shown - 1);
    }
    if (totalW > maxWidth) {
      step = ((maxWidth - tile.width) / (shown - 1)).clamp(6.0, step);
      totalW = tile.width + step * (shown - 1);
    }
  }
  final arcH = tile.height *
      (shown > 12
          ? 0.10
          : shown > 8
              ? 0.16
              : shown > 4
                  ? 0.22
                  : 0.28);
  return DurakOpponentFanGeometry(
    tile: tile,
    step: step,
    totalW: totalW,
    arcH: arcH,
    reserveH: reserveH,
    shown: shown,
  );
}

/// Размер карты в полёте на веер соперника — не мельче читаемой рубашки.
Size durakOpponentFanFlightSize(
  Size tableCard, {
  required bool compact,
}) {
  final scale = compact ? 0.72 : 0.55;
  return Size(
    (tableCard.width * scale).clamp(compact ? 36.0 : 30.0, 60.0),
    (tableCard.height * scale).clamp(compact ? 50.0 : 44.0, 86.0),
  );
}

/// Раздача: достаточно длинная, чтобы слот в веере читался, без паузы.
Duration durakDealFlyDuration({required bool compact}) =>
    Duration(milliseconds: compact ? 260 : 240);

/// Вернулись с другой вкладки на стол — снять застрявшие полёты.
bool shouldSnapDurakVisualOnResume({
  required String? previousPath,
  required String nextPath,
}) {
  final prev = previousPath?.trim() ?? '';
  if (prev.isEmpty) return false;
  if (_isDurakPlayPath(prev)) return false;
  return _isDurakPlayPath(nextPath);
}

/// Стол дурака сейчас на экране — иначе полёты no-op, а карты остаются скрытыми.
bool durakGameUiActive({
  required bool tickerEnabled,
  required String visiblePath,
  required String herePath,
}) {
  if (!tickerEnabled) return false;
  if (visiblePath.trim().isEmpty) return true;
  if (!_isDurakPlayPath(visiblePath)) return false;
  return _isDurakPlayPath(herePath);
}

/// Полёт/busy слишком долго — вёрстка «пропала», нужен snap к серверу.
bool durakVisualLooksStuck({
  required bool busy,
  required bool fxScheduled,
  required bool flightActive,
  required bool hidingTable,
  bool remoteFlightActive = false,
}) =>
    busy ||
    fxScheduled ||
    flightActive ||
    hidingTable ||
    remoteFlightActive;

/// Мини-карта младшего козыря в баннере «кто ходит».
///
/// В альбоме не показываем: достаточно надписи и анимации вытягивания
/// из веера. В портрете мини-карта тоже не нужна — там баннер только текст.
bool durakFirstLeadShowsBannerCard({required bool compact}) => false;

/// В альбоме snap раньше: застрявший кадр сразу режет колоду и кнопку.
/// Раздача живёт дольше 2 с — не режем её одним тиком.
int durakStuckSnapTicks({
  required bool compact,
  bool openingDeal = false,
}) {
  if (openingDeal) return 5;
  return compact ? 2 : 3;
}

/// Кнопка «Бито»/«Взять» не прячется из-за полёта — только из-за жеста в веере.
bool durakActionChromeVisible({
  required bool liveCanShow,
  required bool holdingFanCard,
}) =>
    liveCanShow && !holdingFanCard;

/// Overlay полёта на стол снимать после того, как лицо уже в слоте.
bool durakRevealTableBeforeDismissOverlay({
  required bool tableCardVisible,
}) =>
    tableCardVisible;

/// Добор из колоды: в веере нет карты, пока она ещё pending.
///
/// Взятие со стола не ставит pending — слот-дырка остаётся в [_handOrder].
bool durakDealCardInFanLayout({required bool pendingDeal}) => !pendingDeal;

/// После «Беру» соперника: секунда подписи, потом кнопка «Готово».
const Duration kDurakOpponentTakeHold = Duration(seconds: 1);

/// Веер после своего хода: дырка схлопывается одним коротким твином.
const Duration kDurakFanPlayCloseDuration = Duration(milliseconds: 180);

/// Добор в веер (колода / стол): тот же короткий твин, что после своего хода.
const Duration kDurakFanIncomingDuration = kDurakFanPlayCloseDuration;

/// Твин раскладки веера: быстрый при своём ходе и при входящих картах.
Duration durakFanLayoutTweenDuration({
  required bool compact,
  required bool fastClose,
}) =>
    fastClose
        ? kDurakFanPlayCloseDuration
        : durakLayoutTweenDuration(compact: compact);

/// Показать «Беру», пока держим паузу после взятия соперником.
bool durakShowOpponentTakeLabel({
  required bool takeFollow,
  required bool opponentIsDefender,
  required bool holdActive,
}) =>
    takeFollow && opponentIsDefender && holdActive;

/// «Готово» — только после паузы «Беру».
bool durakShowDoneAfterOpponentTake({
  required bool canDone,
  required bool takeLabelActive,
}) =>
    canDone && !takeLabelActive;

/// Пауза после посадки отбоя, чтобы было видно чем отбились, затем стол в биту.
const Duration kDurakBitoAfterDefensePause = Duration(milliseconds: 900);

/// После последнего отбоя стол ещё виден, потом победа и реванш.
const Duration kDurakFinishAfterLastTrickPause = Duration(milliseconds: 900);

/// Итог и «Повторить» — только когда пауза после последнего трюка прошла.
bool durakFinishChromeVisible({
  required bool isOver,
  required bool finishReady,
}) =>
    isOver && finishReady;

/// Партия только что кончилась на этом экране — ждём посадку и паузу.
bool durakFinishHoldNeeded({
  required bool isOver,
  required bool finishReady,
  required bool alreadyScheduled,
}) {
  if (!isOver || finishReady || alreadyScheduled) return false;
  return true;
}

/// Открыли уже завершённую партию — реванш сразу, без паузы на стол.
bool durakRevealFinishImmediately({
  required bool openedAsObserver,
  required bool firstSnapshotAlreadyOver,
  required bool flightActive,
}) {
  if (openedAsObserver) return true;
  return firstSnapshotAlreadyOver && !flightActive;
}

/// Ждать свои и чужие полёты на стол, прежде чем уводить карты в биту.
bool durakTableReadyForBitoFlight({
  required bool remoteFlying,
  required bool localFlyingToTable,
  required bool defendLock,
  required bool flyingFromHand,
}) =>
    !remoteFlying && !localFlyingToTable && !defendLock && !flyingFromHand;

bool _isDurakPlayPath(String path) {
  final clean = path.split('?').first;
  final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
  if (parts.length < 3 || parts[0] != 'games') return false;
  if (parts[2] == 'offline') return true;
  return parts.length >= 4 && parts[2] == 'game';
}
