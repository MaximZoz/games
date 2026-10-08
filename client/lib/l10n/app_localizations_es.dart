import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Inicio';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navFriends => 'Amigos';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Juegos';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Predeterminado del sistema';

  @override
  String get settingsSoundTitle => 'Sonido';

  @override
  String get settingsSoundSubtitle => 'Juegos y notificaciones';

  @override
  String get settingsSoundGames => 'Juegos';

  @override
  String get settingsSoundNotifications => 'Notificaciones';

  @override
  String get settingsSoundTurn => 'Turno';

  @override
  String get settingsHapticsTitle => 'Vibración';

  @override
  String get settingsHapticsSubtitle => 'Solo avisos: mensajes, solicitudes, tu turno y el temporizador';

  @override
  String get settingsGamepadTitle => 'Mando';

  @override
  String get settingsGamepadSubtitle => 'Mando para menús y partidas';

  @override
  String settingsGamepadConnected(String name) {
    return 'Conectado: $name';
  }

  @override
  String get settingsGamepadDisconnected => 'No hay mando. Conéctalo y pulsa cualquier botón.';

  @override
  String get settingsGamepadGenericName => 'Mando';

  @override
  String get settingsGamepadHelpNavigate => 'Navegar';

  @override
  String get settingsGamepadHelpConfirm => 'Elegir';

  @override
  String get settingsGamepadHelpBack => 'Atrás';

  @override
  String get settingsGamepadHelpTabs => 'Pestañas';

  @override
  String get settingsGamepadHelpPlay => 'Cursor de tablero y mano: damas, tres en raya, hundir la flota, durak, uno, póker y backgammon';

  @override
  String get settingsGamepadHelpCards => 'Cartas';

  @override
  String get settingsGamepadHelpKeyboard => 'Teclado';

  @override
  String get settingsGamepadHelpBalance => 'Saldo';

  @override
  String get settingsGamepadHelpLogout => 'Salir';

  @override
  String get settingsGamepadHelpPage => 'Página';

  @override
  String get settingsGamepadLayoutXbox => 'Disposición Xbox';

  @override
  String get settingsGamepadLayoutPlayStation => 'Disposición PlayStation';

  @override
  String get settingsGamepadLayoutNintendo => 'Disposición Nintendo';

  @override
  String get gamepadKeyboardTitle => 'Teclado';

  @override
  String get gamepadKeyboardSpace => 'Espacio';

  @override
  String get gamepadLegendConfirm => 'Elegir';

  @override
  String get gamepadLegendBack => 'Atrás';

  @override
  String get gamepadLegendTabs => 'Pestañas';

  @override
  String get gamepadLegendCycle => 'Cambiar';

  @override
  String gamepadConnectedSnack(String name) {
    return 'Mando conectado: $name';
  }

  @override
  String get settingsOfflineModeTitle => 'Modo de red';

  @override
  String get settingsOfflineModeSubtitle => 'Sin conexión: juega al instante contra un bot, sin apuestas ni recompensas, sin chats ni amigos. Las compras se guardan y se aplican en modo en línea. En línea — cuando hay internet o por la configuración del usuario.';

  @override
  String get settingsModeOnline => 'En línea';

  @override
  String get settingsModeOffline => 'Sin conexión';

  @override
  String get gamesAlternateStartsHint => 'Por turnos quién empieza la partida';

  @override
  String get rulesAlternateStarts => 'Quién mueve primero alterna de partida a partida.';

  @override
  String get offlineBadgeTooltip => 'Modo sin conexión';

  @override
  String get offlineModePopupTitle => 'Modo sin conexión';

  @override
  String get offlineModePopupBody => 'El modo sin conexión está activado. Juega contra un bot sin apuestas ni recompensas. Chats, amigos y lobby están ocultos. Las compras se aplican en modo en línea.';

  @override
  String get offlineModePopupSettings => 'Ajustes';

  @override
  String get offlineModeOfferBody => 'No hay internet o la conexión es muy lenta. Puedes activar el modo sin conexión y jugar contra un bot.';

  @override
  String get offlineModeOfferAction => 'Activar sin conexión';

  @override
  String get gamesPlay => 'Jugar';

  @override
  String get offlineGameTitle => 'Partida contra un bot';

  @override
  String get offlineGameHint => 'Sin apuestas ni recompensas · solo sin conexión';

  @override
  String get offlineBotWon => 'El bot ganó';

  @override
  String get offlineBotThinking => 'El bot piensa…';

  @override
  String get offlinePlayAgain => 'Otra vez';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Tomar';

  @override
  String get durakActionAll => 'Todas';

  @override
  String get durakActionDone => 'Listo';

  @override
  String get durakActionBito => 'Cubierto';

  @override
  String get durakHintDefend => 'Defiende';

  @override
  String get durakHintDefendOrTransfer => 'Defiende o transfiere';

  @override
  String get durakHintOpponentDefends => 'El rival defiende';

  @override
  String get durakHintThrowInFirst => 'Echa cartas (máx. 5 en el primer cubierto)';

  @override
  String get durakHintThrowIn => 'Echa cartas o espera la defensa';

  @override
  String get durakHintOpponentThrows => 'El rival echa';

  @override
  String get durakHintTakeFollow => 'Echa tras tomar o toca «Listo»';

  @override
  String get durakHintOpponentTakeFollow => 'El rival puede echar tras tomar';

  @override
  String get durakHintBito => 'Echa una carta o di «Cubierto»';

  @override
  String get durakHintOpponentBito => 'El rival echa o dice «Cubierto»';

  @override
  String get durakHintYourAttack => 'Tu turno — ataca';

  @override
  String get durakHintOpponentAttack => 'El rival ataca';

  @override
  String get durakHintYouLost => 'Perdiste — eres el tonto';

  @override
  String get durakHintDrawAllOut => 'Empate — todos salieron';

  @override
  String get durakHintYouFinished => 'Saliste — esperando el final';

  @override
  String get durakFirstLeadYou => 'Tú sales';

  @override
  String get durakFirstLeadOpponent => 'Sale el rival';

  @override
  String get durakFirstLeadBot => 'Sale el bot';

  @override
  String durakFirstLeadOf(String name) {
    return 'Sale $name';
  }

  @override
  String get durakFirstLeadReason => 'Triunfo más bajo';

  @override
  String get shopPurchaseQueued => 'Compra guardada — se aplicará en modo en línea';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — compra aplicada';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — compra no aplicada: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Mensajes solo de amigos';

  @override
  String get settingsFriendsOnlySubtitle => 'Quienes no son amigos solo pueden enviar emojis. Si hay spam, bloquea temporalmente al usuario.';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Amigos';

  @override
  String get settingsPushGames => 'Juegos';

  @override
  String get settingsPushRewards => 'Recompensas';

  @override
  String settingsAppVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get appUpdateTitle => 'Actualización disponible';

  @override
  String get appUpdateBody => 'Hay una nueva versión de la aplicación. Actualiza para continuar.';

  @override
  String get appUpdateWhatsNew => 'Novedades';

  @override
  String get appUpdateOk => 'Actualizar';

  @override
  String get appUpdateLaterBanner => 'Actualizaremos la app después de esta partida';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get loginSubtitle => 'Introduce el correo o usuario y la contraseña';

  @override
  String get loginEmailLabel => 'Correo o usuario';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get loginEmailRequired => 'Introduce el correo o usuario';

  @override
  String get loginPasswordRequired => 'Introduce la contraseña';

  @override
  String get loginTooltip => 'Iniciar sesión';

  @override
  String get logoutTooltip => 'Cerrar sesión';

  @override
  String get registerTitle => 'Registrarse';

  @override
  String get registerSubtitle => 'Crea una cuenta para jugar';

  @override
  String get registerNameLabel => 'Nombre (usuario)';

  @override
  String get registerEmailLabel => 'Correo';

  @override
  String get registerPasswordLabel => 'Contraseña';

  @override
  String get registerSubmit => 'Registrarse';

  @override
  String get registerHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get registerNameRequired => 'Introduce un nombre';

  @override
  String get registerNameNoSpaces => 'El nombre no puede tener espacios';

  @override
  String get registerNameMax => 'Máximo 20 caracteres';

  @override
  String get registerNameHint => 'Hasta 20 caracteres';

  @override
  String get registerEmailRequired => 'Introduce el correo';

  @override
  String get registerEmailInvalid => 'Correo no válido';

  @override
  String get registerPasswordHint => 'Al menos 6 caracteres';

  @override
  String get registerPasswordMin => 'La contraseña debe tener al menos 6 caracteres';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonReply => 'Responder';

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonLoading => 'Cargando…';

  @override
  String get commonError => 'Error';

  @override
  String get commonOnline => 'en línea';

  @override
  String get commonOffline => 'desconectado';

  @override
  String get commonOnlineCap => 'En línea';

  @override
  String get commonUser => 'Usuario';

  @override
  String get commonPlayer => 'Jugador';

  @override
  String get commonAboutMe => 'Sobre mí';

  @override
  String get commonBack => 'Atrás';

  @override
  String get commonAccept => 'Aceptar';

  @override
  String get commonDecline => 'Rechazar';

  @override
  String get commonCreating => 'Creando…';

  @override
  String get commonSearching => 'Buscando…';

  @override
  String get commonInsufficientCoins => 'No hay suficientes monedas';

  @override
  String get commonNotFound => 'No encontrado';

  @override
  String get commonServerErrorShort => 'Error del servidor';

  @override
  String get commonForbidden => 'Acceso denegado';

  @override
  String get commonUserBlocked => 'Usuario bloqueado';

  @override
  String get commonUserNotFound => 'Usuario no encontrado';

  @override
  String get commonGenericError => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get apiErrWrongGameType => 'Tipo de juego incorrecto';

  @override
  String get apiErrWrongGameTypeOrState => 'Tipo o estado de juego incorrecto';

  @override
  String get apiErrLobbyFull => 'El lobby está lleno';

  @override
  String get apiErrBadState => 'Estado de partida no válido';

  @override
  String get apiErrIllegalMove => 'Jugada ilegal';

  @override
  String get apiErrUnknownMoveType => 'Tipo de jugada desconocido';

  @override
  String get apiErrNoOpponents => 'No hay rivales';

  @override
  String get apiErrNoOpponentsRematch => 'No hay rivales para la revancha';

  @override
  String get apiErrAlreadyInLobby => 'Ya estás en este lobby';

  @override
  String get apiErrGameNotActive => 'La partida no está activa';

  @override
  String get apiErrNotInBattle => 'No estás en la fase de combate';

  @override
  String get apiErrNotInSetup => 'No estás en la fase de colocación';

  @override
  String get apiErrAlreadyReady => 'Ya estás listo';

  @override
  String get apiErrAlreadyForfeited => 'Ya te has rendido';

  @override
  String get apiErrYouHaveForfeited => 'Te has rendido';

  @override
  String get apiErrNoDrawOffer => 'No hay oferta de empate';

  @override
  String get apiErrDrawOnlyPvp => 'El empate solo está contra un jugador';

  @override
  String get apiErrDrawOnly1v1 => 'El empate solo está en 1 contra 1';

  @override
  String get apiErrDrawVsBot => 'El empate no está disponible contra un bot';

  @override
  String get apiErrDrawMultiplayer => 'El empate no está disponible en multijugador';

  @override
  String get apiErrDeck24TwoPlayers => 'La baraja de 24 es solo para 2 jugadores';

  @override
  String get apiErrDeck52ThreeOrFour => 'La baraja de 52 es para 3 o 4 jugadores';

  @override
  String get apiErrAccountFrozen => 'La cuenta está congelada';

  @override
  String get apiErrTurnTimeInvalid => 'El tiempo de turno debe ser 0, 20, 60 o 600 segundos';

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String get timeYesterday => 'ayer';

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String get timeWeekAgo => 'hace una semana';

  @override
  String timeWeeksAgo(int count) {
    return 'hace $count sem.';
  }

  @override
  String get timeMonthAgo => 'hace un mes';

  @override
  String timeMonthsAgo(int count) {
    return 'hace $count mes.';
  }

  @override
  String get timeYearAgo => 'hace un año';

  @override
  String timeYearsAgo(int count) {
    return 'hace $count a.';
  }

  @override
  String get weekdaySun => 'Dom';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mié';

  @override
  String get weekdayThu => 'Jue';

  @override
  String get weekdayFri => 'Vie';

  @override
  String get weekdaySat => 'Sáb';

  @override
  String get monthJan => 'Ene';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dic';

  @override
  String get homeAchievements => 'Logros';

  @override
  String get homeAchievementsSubtitle => 'Tus resultados de juego';

  @override
  String get homeAchievementsRewards => 'Recompensas disponibles para reclamar';

  @override
  String get homeCoins => 'Monedas';

  @override
  String get homeCoinsSubtitle => 'Saldo y recompensas';

  @override
  String get homeCoinsDailyReward => 'Recompensa diaria de inicio disponible';

  @override
  String get homeItems => 'Objetos';

  @override
  String get homeItemsInventory => 'Tu inventario';

  @override
  String get homeItemsGifted => 'Alguien te regaló una colección';

  @override
  String get homeItemsIncome => 'Ingresos de colección listos para reclamar';

  @override
  String get homeShop => 'Tienda';

  @override
  String get homeShopSubtitle => 'Emojis, apuestas, colecciones';

  @override
  String get gamesTitle => 'Juegos';

  @override
  String get gamesFindMatch => 'Buscar partida';

  @override
  String get gamesMyTurn => 'Tu turno';

  @override
  String get gamesWaiting => 'Esperando';

  @override
  String get gamesLobbyTab => 'Sala';

  @override
  String get gamesTicTacToe => 'Tres en raya';

  @override
  String get gamesDurak => 'Durak';

  @override
  String get gamesBattleship => 'Battleship';

  @override
  String get gamesBattleshipRandomPlace => 'Place randomly';

  @override
  String get gamesBattleshipConfirmPlace => 'Ready';

  @override
  String get gamesBattleshipRotate => 'Girar';

  @override
  String get gamesBattleshipSetupPhase => 'Setup';

  @override
  String get gamesBattleshipBattlePhase => 'Battle';

  @override
  String get gamesBattleshipWaitingOpponentSetup => 'Waiting for opponent…';

  @override
  String get gamesBattleshipYouWon => 'You won!';

  @override
  String get gamesBattleshipYouLost => 'You lost';

  @override
  String get gamesBattleshipShipsMustNotTouch => 'Ships must not touch';

  @override
  String get rulesBattleshipTitle => 'Battleship — rules';

  @override
  String get rulesBattleshipPlayers => 'Players: 2.';

  @override
  String rulesBattleshipSetupTime(String time) {
    return 'Setup time: $time.';
  }

  @override
  String get rulesBattleshipIntro => '10×10 grid. Fleet: one 4-deck, two 3-deck, three 2-deck and four 1-deck ships. Ships must not touch, including diagonally.';

  @override
  String get rulesBattleshipSetup => 'If setup time runs out, the current valid placement is kept; if it is invalid, a default layout is used.';

  @override
  String get rulesBattleshipPlay => 'After setup, a random player shoots first. Fire at the opponent’s cells: a hit grants another shot, a miss passes the turn. On your turn you see the opponent’s board; on theirs you see yours.';

  @override
  String get rulesBattleshipWin => 'The first to sink the entire enemy fleet wins.';

  @override
  String get gamesPoker => 'Póker';

  @override
  String get gamesUno => 'Uno';

  @override
  String get gamesNardy => 'Backgammon';

  @override
  String get gamesNardyModeShort => 'Corto';

  @override
  String get gamesNardyModeLong => 'Largo';

  @override
  String get gamesCheckers => 'Damas';

  @override
  String get gamesCheckersModeRussian => 'Rusas';

  @override
  String get gamesCheckersModeEnglish => 'Inglesas';

  @override
  String get gamesCheckersModeGiveaway => 'Damas locas';

  @override
  String get gamesCheckersModeCorners => 'Esquinas';

  @override
  String get gamesChess => 'Ajedrez';

  @override
  String get gamesChessModeClassic => 'Clásico';

  @override
  String get gamesChessModeRapid => 'Rápidas';

  @override
  String get gamesChessModeBlitz => 'Blitz';

  @override
  String get gamesChessModeBullet => 'Bala';

  @override
  String get rulesCheckersPlayers => 'Jugadores: 2.';

  @override
  String rulesCheckersMode(String mode) {
    return 'Modo: $mode.';
  }

  @override
  String rulesCheckersTime(String time) {
    return 'Время на ход: $time. Если время вышло — проигрыш.';
  }

  @override
  String get rulesCheckersIntro => 'Tablero 8×8. Dos jugadores.';

  @override
  String get rulesCheckersPlay => 'Capturar es obligatorio. Dama y peón deben seguir mientras desde la casilla de llegada se pueda capturar otra vez: no se puede parar a mitad. Si hay varias direcciones, se puede elegir cualquiera, no necesariamente la más larga. Un peón en la última fila se corona.';

  @override
  String get rulesCheckersWin => 'В русских шашках побеждает тот, кто съел все шашки соперника или лишил его хода. В поддавках наоборот: кто не может ходить — выигрывает.';

  @override
  String get rulesCheckersOfflineBot => 'Офлайн: партия против бота.';

  @override
  String get rulesCheckersPlayRussian => 'Damas rusas: 12 fichas cada uno en casillas oscuras. Los peones avanzan en diagonal y capturan adelante y atrás. Las damas vuelan cualquier número de casillas. Capturar es obligatorio: hay que seguir si se puede, pero se puede elegir cualquier dirección, no necesariamente la más larga. Gana quien capture todas las fichas o deje al rival sin movimientos.';

  @override
  String get rulesCheckersPlayEnglish => 'Damas inglesas: 12 fichas cada uno. Los peones avanzan y capturan solo en diagonal hacia adelante. Las damas avanzan una casilla en diagonal. Capturar es obligatorio. Gana quien capture todas las fichas o deje al rival sin movimientos.';

  @override
  String get rulesCheckersPlayGiveaway => 'Damas locas: los mismos movimientos que las damas rusas, pero el objetivo es el inverso: perder todas las fichas o quedarse sin movimientos. Capturar sigue siendo obligatorio.';

  @override
  String get rulesCheckersPlayCorners => 'Esquinas: las fichas empiezan en esquinas opuestas. Se avanza a una casilla libre vecina en horizontal o vertical, o se salta sobre cualquier ficha sin quitarla. El objetivo es llevar todas las fichas a la esquina del rival.';

  @override
  String get rulesCheckersPlayCornersNoReturn => 'Una ficha que ya salió de su esquina inicial no puede volver a ella.';

  @override
  String get rulesCheckersPlayCornersLeaveHome => 'Las fichas que aún no han salido de casa deben abandonarla en los primeros 25 movimientos del jugador.';

  @override
  String get rulesCheckersDrawRussian => 'Tablas si la posición se repite tres veces o si 15 jugadas de cada lado son solo damas sin captura, también con dos damas por bando.';

  @override
  String get rulesCheckersDrawEnglish => 'Tablas si la posición se repite tres veces, tras 40 jugadas sin captura ni peón, o con una dama contra una dama.';

  @override
  String get rulesCheckersDrawGiveaway => 'Tablas si la posición se repite tres veces o tras 15 jugadas de damas sin captura.';

  @override
  String get rulesCheckersDrawCorners => 'Tablas si la posición se repite tres veces o si 25 jugadas de cada lado no añaden fichas a la esquina objetivo.';

  @override
  String get rulesChessPlayers => 'Jugadores: 2.';

  @override
  String rulesChessMode(String mode) {
    return 'Modo: $mode.';
  }

  @override
  String get rulesChessPlayClassic => 'Tablero 8×8. Cada bando tiene rey, dama, dos torres, dos alfiles, dos caballos y ocho peones. Blancas empiezan. Movimientos habituales, al paso, coronación y enroque. Gana el mate o la retirada.';

  @override
  String get rulesChessDrawClassic => 'Tablas por ahogado, triple repetición, regla de 50 jugadas, material insuficiente o acuerdo.';

  @override
  String get rulesChessClockClassic => 'Reloj: 60+0 — 60 minutos para toda la partida, sin incremento.';

  @override
  String get rulesChessClockRapid => 'Reloj: 10+0 — 10 minutos para toda la partida, sin incremento.';

  @override
  String get rulesChessClockBlitz => 'Reloj: 5+0 — 5 minutos para toda la partida, sin incremento.';

  @override
  String get rulesChessClockBullet => 'Reloj: 3+2 — 3 minutos más 2 segundos por jugada.';

  @override
  String get checkersDrawRepetition => 'Tablas — la posición se repitió tres veces';

  @override
  String get checkersDrawNoProgress => 'Tablas — las jugadas no llevan a la victoria';

  @override
  String get checkersDrawInsufficient => 'Tablas — material insuficiente para ganar';

  @override
  String get rulesNardyTitle => 'Backgammon — reglas';

  @override
  String get rulesNardyPlayers => 'Jugadores: 2.';

  @override
  String rulesNardyMode(String mode) {
    return 'Modo: $mode.';
  }

  @override
  String get rulesNardyIntro => 'Tablero de 24 puntos, 15 fichas cada uno. Dos dados: una ficha la suma o dos fichas los valores.';

  @override
  String get rulesNardyPlayShort => 'Backgammon corto: avanzáis uno hacia el otro y podéis comer fichas solas. La comida va a la barra y debe reentrar. Cuando todas están en casa, las sacáis.';

  @override
  String get rulesNardyPlayLong => 'Backgammon largo: ambos salen de la misma cabeza y van en el mismo sentido. Solo una ficha sale de la cabeza por turno. No se come. Cuando todas están en casa, las sacáis.';

  @override
  String get rulesNardyWin => 'Gana quien primero saque todas sus fichas.';

  @override
  String get rulesNardySixPrime => 'No puedes cerrar seis casillas seguidas mientras ninguna ficha rival las haya pasado.';

  @override
  String get nardyRoll => 'Tirar';

  @override
  String get nardySkipTurn => 'Pasar turno';

  @override
  String get nardyUndoMove => 'Deshacer';

  @override
  String get nardyDoneTurn => 'Listo';

  @override
  String get nardyAutoConfirm => 'Autoconfirmar';

  @override
  String get nardyAutoConfirmHint => 'Pasa el turno automáticamente tras todos los movimientos';

  @override
  String get nardyLayoutToggle => 'Cambiar disposición';

  @override
  String get nardyNoMoves => 'Sin jugadas';

  @override
  String get nardyYourRoll => 'Tu tirada';

  @override
  String get nardyPipsShort => 'Quedan:';

  @override
  String get nardyYouWonMars => '¡Ganaste — gammon!';

  @override
  String get nardyYouLostMars => 'Derrota — gammon';

  @override
  String get rulesNardyOfflineBot => 'Sin conexión: partida contra el bot.';

  @override
  String rulesUnoPlayers(int players) {
    return 'Jugadores: $players.';
  }

  @override
  String get rulesUnoOfflineBot => 'Partida contra un bot, sin límite de tiempo por turno.';

  @override
  String get rulesUnoIntro => 'Cada uno recibe 7 cartas. Juega una carta del mismo color o del mismo valor (número o misma acción).';

  @override
  String get rulesUnoPlay => 'Salto: el siguiente pierde el turno. El cambio de sentido con dos jugadores actúa como salto. +2 solo se apila sobre +2 y +4 solo sobre +4: la penalización se suma (dos +2 hacen robar 4). No se puede poner +2 sobre +4. Quien no apile roba todo el montón y pierde el turno. Dos cartas iguales no negras (por ejemplo dos 8 amarillos) se descartan juntas: juega una y la gemela se lanza sola.';

  @override
  String get rulesUnoWild => 'Una carta negra elige un color nuevo. Juega +4 solo si no tienes carta del color actual. El rival puede impugnarlo: si el +4 era legal, roba 6; si no, el autor del +4 roba 4 y el impugnador juega.';

  @override
  String get rulesUnoDraw => 'Si no tienes carta válida, roba una del mazo. Si encaja, puedes jugarla ahora o quedártela y pasar. No puedes robar si aún tienes jugada.';

  @override
  String get rulesUnoWin => 'En 1v1 hasta 100 puntos; con 3+ jugadores, hasta 200. La ronda la gana quien se queda sin cartas.';

  @override
  String get rulesUnoCall => 'Cuando te quede una carta, pulsa «¡Uno!» al momento. Los demás solo podrán pillarte por olvidar Uno tras un segundo: entonces robas 2 cartas.';

  @override
  String get rulesUnoScoring => 'Quien se queda sin cartas gana la ronda y suma las cartas rivales: números a valor facial, especiales 20, negras 50. En 1v1 hasta 100; con 3+ jugadores, hasta 200.';

  @override
  String get unoColorRed => 'Rojo';

  @override
  String get unoColorYellow => 'Amarillo';

  @override
  String get unoColorGreen => 'Verde';

  @override
  String get unoColorBlue => 'Azul';

  @override
  String get unoDraw => 'Robar';

  @override
  String get unoKeep => 'Conservar';

  @override
  String get unoSayUno => '¡Uno!';

  @override
  String get unoChallengeUno => 'Desafiar Uno';

  @override
  String get unoChallengeWd4 => 'Desafiar +4';

  @override
  String get unoChooseColor => 'Elige un color';

  @override
  String get unoDrawPile => 'Mazo';

  @override
  String get unoDiscardPile => 'Descarte';

  @override
  String unoCardsCount(int count) {
    return 'Cartas: $count';
  }

  @override
  String unoScore(int score) {
    return 'Puntos: $score';
  }

  @override
  String unoRoundProgress(int round, int target) {
    return 'Ronda $round · hasta $target';
  }

  @override
  String get unoYourTurn => 'Tu turno';

  @override
  String get unoWaitingTurn => 'Turno del rival';

  @override
  String get unoChooseColorHint => 'Elige un color para el comodín';

  @override
  String get unoWd4Hint => 'Roba 4 cartas o desafía el Wild +4';

  @override
  String get unoDrawnHint => 'Juega la carta robada o consérvala';

  @override
  String get unoPlayHint => 'Juega un color o valor coincidente';

  @override
  String get unoDrawHint => 'No hay carta válida: roba del mazo';

  @override
  String unoPendingDraw(int count) {
    return '+$count cartas';
  }

  @override
  String get unoYouWon => '¡Ganaste la partida!';

  @override
  String get unoYouLost => 'Partida terminada';

  @override
  String get unoYouLostTimeout => 'Has perdido por tiempo';

  @override
  String unoWinner(String name) {
    return 'Ganador: $name';
  }

  @override
  String unoRoundWonBy(String name) {
    return '$name gana la ronda';
  }

  @override
  String unoRoundPointsAwarded(int points) {
    return '+$points';
  }

  @override
  String get unoRoundContinue => 'Siguiente';

  @override
  String get unoRoundScoresTitle => 'Puntos de la ronda';

  @override
  String get unoDirectionClockwise => 'Sentido horario';

  @override
  String get unoDirectionCounterclockwise => 'Sentido antihorario';

  @override
  String get unoErrStackSameOnly => 'Solo puedes jugar +2 sobre +2, o +4 sobre +4. No se puede apilar +2 sobre +4.';

  @override
  String get unoErrCatchTooEarly => 'Espera un segundo: todavía pueden decir Uno.';

  @override
  String get unoErrCallTooLate => 'Ya no puedes decir Uno. El siguiente jugador ya ha jugado.';

  @override
  String get gamesInDevelopment => 'En desarrollo';

  @override
  String rulesPokerPlayers(int players) {
    return 'Jugadores: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Cada jugador recibe 2 cartas ocultas; en la mesa salen 5 cartas comunitarias.';

  @override
  String get rulesPokerPlay => 'Rondas de apuestas: preflop, flop, turn y river. Puedes fold, call, bet o raise.';

  @override
  String get rulesPokerWin => 'Gana la mejor mano de cinco cartas (ocultas + comunitarias), o el último tras los folds.';

  @override
  String get pokerFold => 'Fold';

  @override
  String get pokerCheck => 'Check';

  @override
  String pokerCall(int amount) {
    return 'Call $amount';
  }

  @override
  String get pokerCallShort => 'Call';

  @override
  String get pokerRaise => 'Raise';

  @override
  String pokerRaiseTo(int amount) {
    return 'Raise to $amount';
  }

  @override
  String get pokerRaiseTitle => 'Raise';

  @override
  String get pokerAllIn => 'All-in';

  @override
  String get pokerAllInBadge => 'All-in';

  @override
  String get pokerFolded => 'Folded';

  @override
  String pokerPot(int amount) {
    return 'Pot: $amount';
  }

  @override
  String get pokerYourTurn => 'Your turn';

  @override
  String pokerToAct(String name) {
    return '$name to act';
  }

  @override
  String pokerWinner(String name) {
    return '$name wins';
  }

  @override
  String get pokerYouWonHand => 'You won the pot!';

  @override
  String pokerWinners(String names) {
    return '$names win';
  }

  @override
  String pokerYouWonHandWith(String names) {
    return 'You and $names won the pot!';
  }

  @override
  String get pokerListAnd => 'and';

  @override
  String get pokerHandOver => 'Hand over';

  @override
  String get pokerStreetPreflop => 'Pre-flop';

  @override
  String get pokerStreetFlop => 'Flop';

  @override
  String get pokerStreetTurn => 'Turn';

  @override
  String get pokerStreetRiver => 'River';

  @override
  String get pokerStreetShowdown => 'Showdown';

  @override
  String get pokerHandHighCard => 'High card';

  @override
  String get pokerHandOnePair => 'One pair';

  @override
  String get pokerHandTwoPair => 'Two pair';

  @override
  String get pokerHandThreeOfAKind => 'Three of a kind';

  @override
  String get pokerHandStraight => 'Straight';

  @override
  String get pokerHandFlush => 'Flush';

  @override
  String get pokerHandFullHouse => 'Full house';

  @override
  String get pokerHandFourOfAKind => 'Four of a kind';

  @override
  String get pokerHandStraightFlush => 'Straight flush';

  @override
  String get pokerHandRoyalFlush => 'Royal flush';

  @override
  String get pokerCombinationsTitle => 'Combinaciones';

  @override
  String pokerHandNumber(int n) {
    return 'Hand $n';
  }

  @override
  String pokerBlinds(int sb, int bb) {
    return 'Blinds $sb/$bb';
  }

  @override
  String get pokerTableYouWon => 'You won the table!';

  @override
  String get pokerNextHandSoon => 'Next hand…';

  @override
  String get pokerShowCards => 'Show cards';

  @override
  String get rulesPokerTable => 'The table plays until one player holds all the chips. Blinds rise every 6–8 hands (heads-up 8, 3-max 7, 4-max 6).';

  @override
  String get gamesRules => 'Reglas';

  @override
  String get gamesRulesTitle => 'Reglas del juego';

  @override
  String get gamesCreate => 'Crear partida';

  @override
  String get gamesJoin => 'Unirse';

  @override
  String get gamesOpponentTurn => 'Turno del rival';

  @override
  String get gamesCurrentGame => 'Partida actual';

  @override
  String get gamesInvitedYou => 'Te invitaron';

  @override
  String get gamesTurnTime => 'Tiempo por turno';

  @override
  String get gamesGridSize => 'Tamaño de la cuadrícula';

  @override
  String get gamesSwapSides => 'Cambio de lado';

  @override
  String get gamesNoCenter => 'Sin inicio en el centro';

  @override
  String get gamesObservation => 'Espectador';

  @override
  String get gamesObservationHint => 'Puedes mirar hasta que termine la partida';

  @override
  String get gamesFinishCurrentFirst => 'Termina primero tu partida actual';

  @override
  String get gamesVariantClassic => 'Clásico';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 jugadores';

  @override
  String get gamesVariantMulti4 => '4 jugadores';

  @override
  String get gamesDurakModePodkidnoi => 'Apoyo';

  @override
  String get gamesDurakModePerevodnoi => 'Traspaso';

  @override
  String get gamesDurakDeck24 => '24 cartas';

  @override
  String get gamesDurakDeck36 => '36 cartas';

  @override
  String get gamesDurakDeck52 => '52 cartas';

  @override
  String rulesDurakMode(String mode) {
    return 'Modo: $mode';
  }

  @override
  String rulesDurakPlayersDeck(int players, String deck) {
    return 'Jugadores: $players. Baraja: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Juega contra un bot, sin apuestas ni límite de tiempo.';

  @override
  String get rulesDurakAttack => 'El atacante juega cartas; el defensor las cubre (mismo palo más alto, o un triunfo). Un triunfo solo se cubre con un triunfo mayor.';

  @override
  String get rulesDurakBeat => 'Cuando todas las cartas están cubiertas, el atacante dice «Bito» y van al descarte. Si no, el defensor se lleva todo de la mesa.';

  @override
  String get rulesDurakLoser => 'Pierde quien se queda con cartas al final: el «tonto».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Jugadores $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Sala $name';
  }

  @override
  String get lobbyMatchmake => 'Sala';

  @override
  String get lobbyPrivateGame => 'Partida privada';

  @override
  String get lobbySearchingOpponent => 'Buscando rival…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Buscando esta partida: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Esperando a que alguien pulse «Buscar partida» o «Unirse»';

  @override
  String get lobbyInviteTitle => 'Invitación a jugar';

  @override
  String get lobbyInvitedToPlay => 'Te invitaron a jugar';

  @override
  String get lobbyEnterGame => 'Entrar a la partida';

  @override
  String get lobbyGone => 'Lobby ya no disponible';

  @override
  String get lobbyInvite => 'Invitar';

  @override
  String get lobbyInviteSent => 'Invitación enviada';

  @override
  String get lobbyCopyLink => 'Compartir enlace de la partida';

  @override
  String get lobbyLinkCopied => 'Enlace copiado';

  @override
  String get lobbyNoFriendsOnline => 'Ningún amigo en línea. Comparte el enlace de arriba o espera a que se conecten.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Rival';

  @override
  String get gameYouWon => '¡Ganaste!';

  @override
  String get gameYouLost => 'Perdiste';

  @override
  String get gameYouWonOpponentLeft => 'Ganaste: el rival abandonó';

  @override
  String get gameYouWonOpponentTimeout => 'Ganaste: al rival se le acabó el tiempo';

  @override
  String get gameDraw => 'Empate';

  @override
  String get gameExitTitle => 'Salir de la partida';

  @override
  String get gameExitConfirm => 'Si sales, perderás. ¿Salir de todos modos?';

  @override
  String get gameStay => 'Quedarse';

  @override
  String get gameLeave => 'Salir';

  @override
  String get gameSurrender => 'Rendirse';

  @override
  String get gameSurrenderTitle => '¿Rendirse?';

  @override
  String get gameSurrenderConfirm => 'Perderás la partida y las monedas de la apuesta.';

  @override
  String get gameOfferDraw => 'Ofrecer tablas';

  @override
  String get gameOfferDrawTitle => '¿Ofrecer tablas?';

  @override
  String get gameOfferDrawConfirm => 'Tu rival puede aceptar o rechazar las tablas.';

  @override
  String get gameAcceptDrawTitle => '¿Aceptar tablas?';

  @override
  String get gameAcceptDrawConfirm => 'La partida terminará en tablas.';

  @override
  String get gameDrawOffered => 'El rival ofrece tablas';

  @override
  String get gameConnecting => 'Conectando a la partida…';

  @override
  String get gameWaitingOpponent => 'Esperando al rival';

  @override
  String get gameRematchOffer => 'El rival propone una revancha';

  @override
  String get gameRematchDeclined => 'El rival rechazó la revancha';

  @override
  String get gameRematch => 'Revancha';

  @override
  String get gameOtherOpponent => 'Otro rival';

  @override
  String get gameSwapSidesAction => 'Cambiar de lado';

  @override
  String get gameWriteMessage => 'Escribir un mensaje';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Aún no hay chats.\nToca el icono de arriba a la derecha para elegir un amigo y empezar a hablar.';

  @override
  String get chatsNewChat => 'Nuevo chat';

  @override
  String get chatsNoMessages => 'Sin mensajes';

  @override
  String get chatsClearTitle => '¿Borrar la conversación?';

  @override
  String get chatsClearDesc => 'El chat se eliminará de forma permanente.';

  @override
  String get chatsClearConfirm => 'Borrar';

  @override
  String get chatsBlockTitle => '¿Bloquear a este usuario?';

  @override
  String get chatsBlockDesc => 'Ya no podrán enviarse mensajes. Se eliminarán el chat y la amistad.';

  @override
  String get chatsBlockConfirm => 'Bloquear';

  @override
  String get chatsBlockedUsers => 'Usuarios bloqueados';

  @override
  String get chatsUnblock => 'Desbloquear';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Aún no hay mensajes.\nEnvía el primero.';

  @override
  String get chatMessageHint => 'Mensaje';

  @override
  String get chatPaste => 'Pegar';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Compra emojis en la tienda de la pantalla de inicio';

  @override
  String get chatEditing => 'Editando';

  @override
  String get chatToday => 'Hoy';

  @override
  String get chatYesterday => 'Ayer';

  @override
  String get chatFriendsOnly => 'Texto solo para amigos';

  @override
  String get emojiGroupEmotions => 'Emociones';

  @override
  String get emojiGroupGame => 'Juegos';

  @override
  String get emojiGroupFlags => 'Banderas';

  @override
  String get emojiGroupAnimals => 'Animales';

  @override
  String get emojiGroupFood => 'Comida';

  @override
  String get emojiGroupTravel => 'Viajes';

  @override
  String get emojiGroupParty => 'Celebración';

  @override
  String get emojiGroupObjects => 'Objetos';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsTabFriends => 'Amigos';

  @override
  String get friendsTabIncoming => 'Entrantes';

  @override
  String get friendsTabOutgoing => 'Salientes';

  @override
  String get friendsAdd => 'Añadir amigo';

  @override
  String get friendsRequestSent => 'Solicitud enviada';

  @override
  String get friendsFindTab => 'Buscar amigo';

  @override
  String get friendsSearchHint => 'Buscar por nombre de usuario';

  @override
  String get friendsSearchPrompt => 'Usa la búsqueda para encontrar nuevos amigos';

  @override
  String get friendsNothingFound => 'No se encontró nada';

  @override
  String get friendsEmpty => 'Aún no tienes amigos';

  @override
  String get friendsSearchNoMatches => 'Ningún amigo coincide con la búsqueda';

  @override
  String get friendsIncomingSearchNoMatches => 'Ninguna solicitud recibida coincide';

  @override
  String get friendsOutgoingSearchNoMatches => 'Ninguna solicitud enviada coincide';

  @override
  String get friendsNoIncoming => 'No hay solicitudes entrantes';

  @override
  String get friendsNoOutgoing => 'No hay solicitudes salientes';

  @override
  String get friendsAlreadyFriends => 'Ya sois amigos';

  @override
  String get friendsRemoveTitle => '¿Eliminar de amigos?';

  @override
  String get friendsRemoved => 'Eliminado de amigos';

  @override
  String get friendsRequestAccepted => 'Solicitud aceptada';

  @override
  String get friendsRequestDeclined => 'Solicitud rechazada';

  @override
  String get friendsRequestCancelled => 'Solicitud cancelada';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSignInPrompt => 'Inicia sesión en tu cuenta';

  @override
  String get profileSignInHint => 'Para configurar tu perfil personal';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileCollections => 'Colecciones';

  @override
  String get profileAge => 'Edad';

  @override
  String get profileGender => 'Género';

  @override
  String get profileGenderUnset => 'Sin definir';

  @override
  String get profileGenderMale => 'Hombre';

  @override
  String get profileGenderFemale => 'Mujer';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Subir foto';

  @override
  String get profileChangePhoto => 'Cambiar avatar';

  @override
  String get shopTitle => 'Tienda';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Emojis animados para el chat';

  @override
  String get shopCollections => 'Colecciones';

  @override
  String get shopCollectionsSubtitle => 'Escaparate del perfil, regalos e ingresos';

  @override
  String get shopStakes => 'Apuestas';

  @override
  String get shopStakesSubtitle => 'Desbloquear apuestas más altas';

  @override
  String get shopEmojisHelp => 'Emojis animados para el chat. Compra un set y envíalos en mensajes a tus amigos.';

  @override
  String get shopCollectionsHelp => 'Solo se puede vender una colección nueva o vintage: el 80 % del precio si es nueva y el 300 % del precio si es vintage. Las gastadas, cansadas y deterioradas no se pueden vender.\n\nReúne un conjunto de objetos: aparecen en el escaparate del perfil y se pueden regalar. Cada objeto da monedas cada día, y un conjunto completo da además un bono aparte.\n\nEl ingreso diario de un objeto depende del estado y es una parte de la suma habitual. Nuevo da el 100 %. Gastado da el 60 %. Cansado da el 40 %. Deteriorado da el 100 %. Un objeto vintage da el 200 %, el doble del ingreso habitual.\n\nEl bono del conjunto completo no cambia hasta que el conjunto sea vintage. Un conjunto es vintage cuando cada objeto lo es: el bono pasa a ser el 300 %, el triple de lo habitual.\n\nEl estado depende de cuánto tiempo llevas el objeto. Nuevo — los primeros 7 días. Gastado — del día 8 a 2 meses. Cansado — de 2 a 6 meses. Deteriorado — de 6 meses a 1 año. Vintage — a partir de 1 año.';

  @override
  String get shopStakesHelp => 'Desbloquea apuestas más altas. Cuanto mayor sea la apuesta, mayor será el bote y el premio.';

  @override
  String get inventoryTitle => 'Objetos';

  @override
  String get inventoryEmpty => 'Aún no hay nada aquí: mira la tienda';

  @override
  String get inventoryFrames => 'Marcos';

  @override
  String get inventoryClaim => 'Reclamar';

  @override
  String get inventorySell => 'Vender';

  @override
  String get inventoryGift => 'Regalar';

  @override
  String get messageEdited => 'editado';

  @override
  String get messageDeleted => 'Mensaje eliminado';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Cámara';

  @override
  String get gallery => 'Galería';

  @override
  String get connectionError => 'No se pudo conectar al servidor.';

  @override
  String get serverError => 'Error del servidor. Inténtalo de nuevo más tarde.';

  @override
  String get sessionExpired => 'La sesión expiró. Vuelve a iniciar sesión.';

  @override
  String get errNoInternet => 'Sin conexión a Internet.';

  @override
  String get errTimeout => 'Se agotó el tiempo de espera. Inténtalo de nuevo.';

  @override
  String get errGamesUnavailable => 'Los juegos no están disponibles temporalmente';

  @override
  String get errSettingsSaveFailed => 'No se pudo guardar el ajuste';

  @override
  String get errPushPermission => 'Permite las notificaciones en el navegador o en los ajustes del sistema.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Bronce';

  @override
  String get coinSilver => 'Plata';

  @override
  String get coinGold => 'Oro';

  @override
  String get coinDiamond => 'Diamante';

  @override
  String get balanceZeroBronze => '0 de bronce';

  @override
  String balanceBronzes(int count) {
    return '$count de bronce';
  }

  @override
  String balanceSilvers(int count) {
    return '$count de plata';
  }

  @override
  String balanceGolds(int count) {
    return '$count de oro';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamantes';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/día';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'pl.';

  @override
  String get balanceAbbrGold => 'oro';

  @override
  String get commonBackHome => 'Volver al inicio';

  @override
  String get commonCopied => 'Copiado';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonTryLater => 'Inténtalo más tarde.';

  @override
  String get commonTryRefresh => 'Prueba a actualizar la página.';

  @override
  String get coinsTitle => 'Monedas';

  @override
  String get coinsLoginReward => 'Recompensa por inicio de sesión';

  @override
  String get coinsLoginAvailableToday => 'Recompensa de hoy disponible';

  @override
  String get coinsLoginStreak => 'Racha diaria de inicios de sesión';

  @override
  String get coinsFriendReward => 'Recompensa por amigo';

  @override
  String get coinsTasks => 'Tareas';

  @override
  String get coinsTasksSubtitle => 'Recompensas por perfil, amigos y partidas';

  @override
  String get coinsTasksRewards => 'Recompensas disponibles para reclamar';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount por registrarse con tu enlace';
  }

  @override
  String get coinsLoadRewardsFailed => 'No se pudieron cargar las recompensas';

  @override
  String get coinsClaimReward => 'Reclamar recompensa';

  @override
  String get coinsAlreadyClaimed => 'Ya reclamada';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · hoy';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · queda 1 día';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · quedan $remaining';
  }

  @override
  String get coinsInviteFriend => 'Invita a un amigo';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount por cada persona que se registre con tu enlace';
  }

  @override
  String get coinsCopyLink => 'Copiar enlace';

  @override
  String get coinsHowItWorks => 'Cómo funciona';

  @override
  String get coinsHowStep1 => 'Copia el enlace y envíaselo a un amigo';

  @override
  String get coinsHowStep2 => 'Tu amigo se registra con ese enlace';

  @override
  String coinsHowStep3(String amount) {
    return 'Recibes $amount';
  }

  @override
  String get achievementsTitle => 'Logros';

  @override
  String achievementsProgress(String progress) {
    return 'Progreso: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Marco obtenido';

  @override
  String get achievementsClaimed => 'Obtenido';

  @override
  String get achievementsOpenFrame => 'Abrir marco';

  @override
  String friendsRemoveConfirm(String name) {
    return '¿Seguro que quieres eliminar a $name de amigos?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Quitar';

  @override
  String get friendsRemove => 'Eliminar de amigos';

  @override
  String get friendsAcceptRequest => 'Aceptar solicitud';

  @override
  String get friendsDeclineRequest => 'Rechazar solicitud';

  @override
  String get friendsCancelRequest => 'Cancelar solicitud';

  @override
  String get friendsSendRequest => 'Enviar solicitud de amistad';

  @override
  String get friendsRequestAlreadySent => 'Solicitud ya enviada';

  @override
  String get friendsIncomingStatus => 'Solicitud entrante';

  @override
  String get friendsOutgoingStatus => 'Solicitud saliente';

  @override
  String get friendsNotFriends => 'No sois amigos';

  @override
  String get friendsCollapseSearch => 'Ocultar búsqueda';

  @override
  String get friendsExpandSearch => 'Mostrar búsqueda';

  @override
  String get friendsLoadFailed => 'No se pudieron cargar los amigos';

  @override
  String friendsSince(String date) {
    return 'Amigos desde: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Solicitud entrante: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Solicitud saliente: $date';
  }

  @override
  String get userInfoTitle => 'Información del usuario';

  @override
  String profileAgeYears(int age) {
    return '$age años';
  }

  @override
  String get shopBuy => 'Comprar';

  @override
  String get shopBuyTitle => '¿Comprar?';

  @override
  String get shopBuyStakeTitle => '¿Comprar apuesta?';

  @override
  String get shopBuyEmojiTitle => '¿Comprar emoji?';

  @override
  String get shopBuyCollectionTitle => '¿Comprar colección?';

  @override
  String shopPrice(String price) {
    return 'Precio: $price';
  }

  @override
  String get shopOwned => 'Comprado';

  @override
  String get shopHave => 'Tienes';

  @override
  String get shopEmpty => 'Aún vacío';

  @override
  String shopPurchased(String title) {
    return '$title comprado';
  }

  @override
  String get shopEmojiUses => 'Obtienes: 10 usos';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 usos';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 usos';
  }

  @override
  String get shopBuyTen => 'Comprar · 10 uds.';

  @override
  String shopDailyIncome(String amount) {
    return 'Ingresos: $amount';
  }

  @override
  String get shopBuyOnce => 'Compra única';

  @override
  String get shopSellRefund => 'La venta depende del estado de la colección';

  @override
  String get collectionConditionNew => 'Nuevo';

  @override
  String get collectionConditionWorn => 'Gastado';

  @override
  String get collectionConditionTired => 'Cansado';

  @override
  String get collectionConditionShabby => 'Deteriorado';

  @override
  String get collectionConditionVintage => 'Vintage';

  @override
  String shopCollectionAdded(String title) {
    return '$title añadido al perfil';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bonus de set +$percent%';
  }

  @override
  String get shopSetComplete => 'Completo';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Recogido · $owned/$total';
  }

  @override
  String get inventorySellTitle => '¿Vender?';

  @override
  String inventorySellDesc(String amount) {
    return 'Recibirás $amount';
  }

  @override
  String get inventoryCollectionNotSellable => 'Solo se puede vender una colección nueva o vintage.';

  @override
  String inventorySold(String amount) {
    return 'Vendido: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Primero añade amigos';

  @override
  String get inventoryGiftTitle => '¿Regalar colección?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return '¿Regalar «$title» a $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Regalado: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'El jugador ya tiene este objeto';

  @override
  String get inventoryGiftSelf => 'No puedes regalarte a ti mismo';

  @override
  String get inventoryGiftNotOwned => 'Este objeto no está en tu inventario';

  @override
  String get inventoryLoadFailed => 'No se pudieron cargar los objetos';

  @override
  String get inventoryNoCollections => 'Sin colecciones — cómpralas en la tienda';

  @override
  String get inventoryNoEmojis => 'Sin emojis — cómpralos en la tienda';

  @override
  String get inventoryNoFrames => 'Sin marcos — gana 10 partidas de liga (logros)';

  @override
  String get inventoryNoStakes => 'Sin apuestas compradas';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Quedan $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Ingresos: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Ingresos mañana: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Listo';

  @override
  String get inventoryIncomeTomorrowLabel => 'Mañana';

  @override
  String inventoryStakeGold(String amount) {
    return 'Puedes apostar $amount de oro';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Puedes apostar $amount de plata';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Recibido +$amount';
  }

  @override
  String get chatsLoadFailed => 'No se pudieron cargar los chats';

  @override
  String get chatsLoadListFailed => 'No se pudo cargar la lista';

  @override
  String get chatsBlockedEmpty => 'La lista está vacía';

  @override
  String chatsBlockedAt(String date) {
    return 'Bloqueado: $date';
  }

  @override
  String get chatsCreateFailed => 'No se pudo crear el chat';

  @override
  String get chatsNeedFriendsFirst => 'Primero añade amigos; luego podrás abrir un chat.';

  @override
  String get chatsFriendsNotFound => 'No se encontraron amigos';

  @override
  String get chatsFindFriendHint => 'Buscar amigo por apodo';

  @override
  String get chatsSelectChat => 'Selecciona un chat';

  @override
  String get chatsSelectHint => 'Elige una conversación de la lista de la izquierda';

  @override
  String get chatEditFailed => 'No se pudo editar el mensaje';

  @override
  String get chatSendFailed => 'No se pudo enviar el mensaje';

  @override
  String get chatDeleteFailed => 'No se pudo eliminar el mensaje';

  @override
  String get chatEmojiSendFailed => 'No se pudo enviar el emoji';

  @override
  String get chatLoadFailed => 'No se pudieron cargar los mensajes';

  @override
  String get chatBackToGame => 'Volver al juego';

  @override
  String get chatBackToChats => 'Volver a los chats';

  @override
  String get chatActions => 'Acciones del chat';

  @override
  String get chatAutoTranslate => 'Traducción automática';

  @override
  String get chatScrollToEnd => 'Ir al final';

  @override
  String chatReplyingTo(String name) {
    return 'Respondiendo a $name';
  }

  @override
  String get chatGift => 'Regalo';

  @override
  String get chatCollection => 'Colección';

  @override
  String get chatGiftCollection => 'Regalo · colección';

  @override
  String get chatThisUser => 'este usuario';

  @override
  String get gamesLobbyLoadFailed => 'No se pudo cargar el lobby.';

  @override
  String get gamesTapChangeStake => 'Toca para cambiar la apuesta';

  @override
  String get gamesTapChangeTurnTime => 'Toca para cambiar el tiempo por turno';

  @override
  String get gamesTapChangeGrid => 'Toca para cambiar el tamaño de la cuadrícula';

  @override
  String get gamesSwapSidesHint => 'O puede convertirse en X tras el 1.er movimiento';

  @override
  String get gamesNoCenterHint => 'El primer movimiento no puede ser al centro';

  @override
  String get lobbyInviteSentShort => 'Enviado';

  @override
  String get lobbySearchShort => 'Buscar';

  @override
  String get lobbySearchPlayers => 'Buscar jugadores';

  @override
  String get lobbyInviteDeclinedShort => 'Rechazado';

  @override
  String get lobbyInvitesSentWaiting => 'Invitaciones enviadas. Esperando respuesta.';

  @override
  String get lobbyLinkCopiedHint => 'Pégalo en un chat o mensaje a un amigo';

  @override
  String get lobbyCopyLinkHint => 'Copiar enlace al portapapeles';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name te invita a jugar';
  }

  @override
  String gameOpponentWon(String name) {
    return 'Ganó $name';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'Se acabó el tiempo. Ganó $name';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Torneos';

  @override
  String get profileAgeInvalid => 'Introduce una edad de 1 a 111';

  @override
  String get profileSaveFailed => 'No se pudo guardar el perfil';

  @override
  String get profileNameHint => 'Letras latinas, dígitos, _ hasta 10 caracteres';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'De 1 a 111';

  @override
  String get profileAboutHint => 'Hasta 100 caracteres (opcional)';

  @override
  String get profileProcessingPhoto => 'Procesando foto…';

  @override
  String get profileCropTitle => 'Elige el área del avatar';

  @override
  String get profileCropHint => 'Amplía y mueve la foto';

  @override
  String get profileApply => 'Aplicar';

  @override
  String get profilePreparing => 'Preparando…';

  @override
  String get profileGalleryTitle => 'Fotos';

  @override
  String get profileGalleryAdd => 'Añadir foto';

  @override
  String get profileMakePrimary => 'Hacer principal';

  @override
  String get profilePhotoDelete => 'Eliminar foto';

  @override
  String get profilePhotosLimit => 'Puedes subir hasta 3 fotos';

  @override
  String get profilePhotosEmpty => 'Aún no hay fotos';

  @override
  String get profilePhotoUploadFailed => 'No se pudo subir la foto';

  @override
  String get profilePhotoDeleteFailed => 'No se pudo eliminar la foto';

  @override
  String get profilePhotoTooLarge => 'La foto es demasiado grande';

  @override
  String get profileSetPrimaryFailed => 'No se pudo establecer como principal';

  @override
  String timeSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get timeOneMin => '1 min';

  @override
  String get timeTenMin => '10 min';

  @override
  String rulesIntro(String grid) {
    return 'Tres en raya en un tablero $grid. Por turnos; empieza X.';
  }

  @override
  String rulesWin(int n) {
    return 'Victoria: alinea $n en fila horizontal, vertical o diagonal.';
  }

  @override
  String get rulesNoTimeLimit => 'Sin límite de tiempo por turno.';

  @override
  String rulesTurnTime(String time) {
    return 'Tiempo por turno: $time. Si se acaba el tiempo, pierdes.';
  }

  @override
  String rulesStake(String stake) {
    return 'Apuesta: $stake. La partida es por tantas monedas.';
  }

  @override
  String get rulesSwap => 'Cambio de lados: O puede intercambiarse con X tras el primer movimiento de X.';

  @override
  String get rulesNoCenter => 'Sin centro: X no puede jugar en el centro en el primer movimiento.';

  @override
  String get collectionSetLegends => 'Leyendas';

  @override
  String get collectionSetSpace => 'Espacio';

  @override
  String get collectionSetGems => 'Gemas';

  @override
  String get collectionSetParty => 'Fiesta';

  @override
  String get collectionSetNature => 'Naturaleza';

  @override
  String get collectionSetAdventures => 'Aventuras';

  @override
  String collectionCardMeta(String amount) {
    return 'Colección · vitrina · regalo · venta · +$amount';
  }

  @override
  String get coinsDayOne => 'día';

  @override
  String get coinsDayFew => 'días';

  @override
  String get coinsDayMany => 'días';

  @override
  String get giftFriendTitle => 'Regalar a un amigo';

  @override
  String photoCount(int count) {
    return 'Foto ($count)';
  }

  @override
  String photoCountWithText(int count, String text) {
    return 'Foto ($count): $text';
  }

  @override
  String photoWithText(String text) {
    return 'Foto: $text';
  }

  @override
  String shopEmojiGroupMeta(int count, String price) {
    return '$count emojis · a $price';
  }

  @override
  String get chatsExpandPanel => 'Expandir panel';

  @override
  String get chatsCollapsePanel => 'Contraer panel';

  @override
  String get chatReplySourceMissing => 'Mensaje original no encontrado';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Apuesta $n plata';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Apuesta $n oro';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Desbloquea apostar $n de plata';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Desbloquea apostar $n de oro';
  }

  @override
  String get chatReplySelf => 'ti mismo';

  @override
  String get chatReplyPeer => 'al interlocutor';

  @override
  String get verifyEmailTitle => 'Verify email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get verifyEmailCodeLabel => 'Code from email';

  @override
  String get verifyEmailCodeRequired => 'Enter the code';

  @override
  String get verifyEmailSubmit => 'Verify';

  @override
  String get verifyEmailResend => 'Resend code';

  @override
  String get verifyEmailResent => 'A new code was sent';

  @override
  String get oauthOrContinue => 'or continue with';

  @override
  String get oauthGoogle => 'Google';

  @override
  String get oauthApple => 'Apple';

  @override
  String get oauthYandex => 'Yandex';

  @override
  String get oauthVK => 'VK';

  @override
  String get oauthError => 'Could not sign in with this service';

  @override
  String get oauthCallbackTitle => 'Signing in…';

  @override
  String verifyEmailResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String verifyEmailDevCodeHint(String code) {
    return 'Email is not configured on the server yet. Use this code: $code';
  }

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle => 'Enter your email — we’ll send a code for a new password';

  @override
  String get forgotPasswordSubmit => 'Send code';

  @override
  String get forgotPasswordSent => 'If the account exists, a code was sent to your email';

  @override
  String get resetPasswordTitle => 'New password';

  @override
  String resetPasswordSubtitle(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get resetPasswordCodeLabel => 'Code from email';

  @override
  String get resetPasswordCodeRequired => 'Enter the code';

  @override
  String get resetPasswordNewLabel => 'New password';

  @override
  String get resetPasswordNewRequired => 'Enter a new password';

  @override
  String get resetPasswordNewShort => 'At least 6 characters';

  @override
  String get resetPasswordConfirmLabel => 'Confirm password';

  @override
  String get resetPasswordConfirmMismatch => 'Passwords do not match';

  @override
  String get resetPasswordSubmit => 'Save password';

  @override
  String get resetPasswordResend => 'Resend code';

  @override
  String get resetPasswordResent => 'A new code was sent';

  @override
  String resetPasswordResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get resetPasswordBackToLogin => 'Back to sign in';

  @override
  String get statsTitle => 'Estadísticas';

  @override
  String get statsLoadFailed => 'No se pudieron cargar las estadísticas';

  @override
  String get statsAllGames => 'Todos los juegos';

  @override
  String get statsEmptyTitle => 'Aún no hay partidas jugadas';

  @override
  String get statsEmptyHint => 'Juega tu primera partida para ver las estadísticas aquí.';

  @override
  String get statsWins => 'Victorias';

  @override
  String get statsDraws => 'Empates';

  @override
  String get statsLosses => 'Derrotas';

  @override
  String get statsWinRate => 'Porcentaje de victorias';

  @override
  String get statsTopWon => 'Más victorias contra';

  @override
  String get statsTopDrawn => 'Más empates con';

  @override
  String get statsTopLost => 'Más derrotas contra';

  @override
  String get statsTimePlayed => 'Tiempo de juego';

  @override
  String get statsYourScore => 'Tu marcador';

  @override
  String get profileShowStats => 'Mostrar estadísticas';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'El rival se rindió. ¡Has ganado!';

  @override
  String get lobbyLeaveTitle => '¿Salir del lobby?';

  @override
  String get lobbyLeaveConfirm => 'El lobby se eliminará al salir. Los amigos invitados recibirán un rechazo.';

  @override
  String get lobbyLeave => 'Salir';

  @override
  String statsDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String statsDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String statsDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String gameYouForfeitOpponentWon(String name) {
    return 'Te rendiste. $name ganó';
  }

  @override
  String get supportTitle => 'Soporte';

  @override
  String get supportUnavailable => 'El soporte no está disponible';

  @override
  String get supportOpenFailed => 'No se pudo abrir el chat de soporte';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Se te han acreditado $amount monedas';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return 'Se dedujeron $amount monedas';
  }

  @override
  String get coinsCreditCardTitle => 'Se te han acreditado monedas';

  @override
  String get coinsClaim => 'Reclamar';

  @override
  String get durakActionPass => 'Pasar';

  @override
  String get durakRoleTook => 'Toma';

  @override
  String get durakRoleBeats => 'Cubre';

  @override
  String get durakRoleThrowIn => 'Apoyo';

  @override
  String get durakRoleTurn => 'Turno';

  @override
  String get durakRoleDefends => 'Defiende';

  @override
  String get durakStatusTaking => 'Toma';

  @override
  String get durakHintDefenderTurn => 'Turno del defensor';

  @override
  String get gameYouEliminated => 'Has sido eliminado';

  @override
  String gameYouPlaced(int place) {
    return 'Quedaste $placeº';
  }

  @override
  String get gameOverNeutral => 'Partida terminada';

  @override
  String gameTurnOf(String name) {
    return 'Turno de $name';
  }

  @override
  String get chatGroupTooltip => 'Chat de grupo';

  @override
  String get lobbyChatNotReady => 'El chat del lobby aún no está listo';

  @override
  String get chatsGroupChat => 'Chat de grupo';

  @override
  String chatsMembersCount(int count) {
    return 'Miembros: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count pers.';
  }

  @override
  String get chatsYouSuffix => '(tú)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 jugadores';

  @override
  String get chatTitleDurak4 => 'Durak · 4 jugadores';

  @override
  String get rulesTttUltimate => 'Ultimate: nueve minitableros 3×3. Una jugada envía al rival a ese minitablero. Gana quien complete una línea en el metatablero.';

  @override
  String get rulesTttMulti3 => '3 jugadores: tablero 3×3, tres jugadores (X, O, △). Completa una línea con tus marcas para ganar.';

  @override
  String get rulesTttMulti4 => '4 jugadores: tablero 4×4, cuatro jugadores (X, O, △, □). Completa una línea con tus marcas para ganar.';

  @override
  String get adminUsersTab => 'Usuarios';

  @override
  String get adminSupportTab => 'Soporte';

  @override
  String get adminSearchHint => 'Buscar por email o apodo';

  @override
  String get adminRoleAdmins => 'Admins';

  @override
  String get adminRoleUsers => 'Usuarios';

  @override
  String get adminRoleAll => 'Todos los roles';

  @override
  String get adminStatusFrozen => 'Congelados';

  @override
  String get adminStatusActive => 'Activos';

  @override
  String get adminStatusAny => 'Cualquier estado';

  @override
  String get adminOrderDesc => 'Descendente';

  @override
  String get adminOrderAsc => 'Ascendente';

  @override
  String adminLoadFailed(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get adminUsersEmpty => 'No hay usuarios';

  @override
  String get adminSortLastSeen => 'Por última visita';

  @override
  String get adminSortEmail => 'Por email';

  @override
  String get adminSortCreated => 'Por fecha de registro';

  @override
  String adminBronzeBalance(int amount) {
    return '$amount br.';
  }

  @override
  String get adminRevokeAdmin => 'Quitar admin';

  @override
  String get adminGrantAdmin => 'Hacer admin';

  @override
  String get adminAdminRevoked => 'Permisos de admin quitados';

  @override
  String get adminAdminGranted => 'Permisos de admin concedidos';

  @override
  String get adminGrantCoins => 'Añadir monedas';

  @override
  String get adminWriteSupport => 'Escribir como soporte';

  @override
  String get adminUnfreeze => 'Descongelar';

  @override
  String get adminFreeze => 'Congelar';

  @override
  String get adminUnfrozen => 'Descongelado';

  @override
  String get adminFrozenDone => 'Congelado';

  @override
  String get adminResetPassword => 'Restablecer contraseña';

  @override
  String get adminCoinsAmountHint => 'Cantidad (negativo = descuento)';

  @override
  String get adminReasonOptional => 'Motivo (opcional)';

  @override
  String get adminGrantSent => 'Tarjeta enviada al chat de soporte';

  @override
  String adminCoinsDebited(int amount) {
    return 'Descontadas $amount de bronce';
  }

  @override
  String get adminGrantVerb => 'Añadir';

  @override
  String get adminNewPasswordHint => 'Nueva contraseña (mín. 6)';

  @override
  String get adminPasswordReset => 'Contraseña restablecida';

  @override
  String get adminResetVerb => 'Restablecer';

  @override
  String adminShortError(String error) {
    return 'Error: $error';
  }

  @override
  String get adminSupportEmpty => 'No hay solicitudes de soporte';

  @override
  String get adminUserFallback => 'Usuario';

  @override
  String get apiErrTooManyRequests => 'Demasiadas solicitudes. Inténtalo más tarde.';

  @override
  String get apiErrMoveConflict => 'Conflicto de jugada. Inténtalo de nuevo.';

  @override
  String get shopElixirs => 'Elixires';

  @override
  String get shopElixirsSubtitle => 'Rejuvenecer, envejecer o acelerar colecciones';

  @override
  String get shopElixirsHelp => 'Tres estantes: rejuvenecimiento, envejecimiento y aceleración. En cada uno hay seis elixires, uno por conjunto. Un elixir solo actúa sobre su conjunto.\n\nEl rejuvenecimiento adelanta un estado y nunca pasa de nuevo. El envejecimiento retrasa un estado y nunca pasa de gastado. La aceleración solo en gastado: quedan 3 meses para vintage, una vez. Un elixir no otorga vintage.\n\nEl elixir comprado está en Objetos. Se usa desde la colección o desde el propio elixir. Cada uso gasta uno.';

  @override
  String get elixirGroupRejuvenate => 'Rejuvenecimiento';

  @override
  String get elixirGroupAge => 'Envejecimiento';

  @override
  String get elixirGroupAccelerate => 'Aceleración';

  @override
  String get elixirEffectRejuvenate => 'rejuvenecimiento';

  @override
  String get elixirEffectAge => 'envejecimiento';

  @override
  String get elixirEffectAccelerate => 'aceleración';

  @override
  String get elixirAdjCelebration => 'festivo';

  @override
  String get elixirAdjNature => 'natural';

  @override
  String get elixirAdjLegends => 'legendario';

  @override
  String get elixirAdjCosmic => 'cósmico';

  @override
  String get elixirAdjAdventure => 'de aventura';

  @override
  String get elixirAdjJewels => 'precioso';

  @override
  String elixirName(String adjective, String effect) {
    return 'Elixir $adjective de $effect';
  }

  @override
  String get elixirHelpRejuvenate => 'Adelanta la colección un estado. No más nuevo que nuevo.';

  @override
  String get elixirHelpAge => 'Retrasa la colección un estado. No más viejo que gastado.';

  @override
  String get elixirHelpAccelerate => 'Solo si está gastada. Quedan 3 meses para vintage, una vez.';

  @override
  String get elixirUseRejuvenate => 'Rejuvenecer';

  @override
  String get elixirUseAge => 'Envejecer';

  @override
  String get elixirUseAccelerate => 'Acelerar';

  @override
  String get elixirUse => 'Usar';

  @override
  String collectionLeftDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '$count día',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '$count hora',
    );
    return '$_temp0';
  }

  @override
  String collectionLeftMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '$count minuto',
    );
    return '$_temp0';
  }

  @override
  String elixirSetOnly(String set) {
    return 'Solo el conjunto «$set».';
  }

  @override
  String get elixirPickCollection => 'Elige una colección';

  @override
  String get elixirNoTarget => 'Ninguna colección de este conjunto admite este elixir';

  @override
  String get elixirApplied => 'Elixir aplicado';

  @override
  String get elixirConfirmTitle => '¿Usar este elixir?';

  @override
  String elixirConfirmBody(String elixir, String collection) {
    return '$elixir\n$collection';
  }

  @override
  String get inventoryNoElixirs => 'No hay elixires — cómpralos en la tienda';

  @override
  String get elixirNotApplicable => 'Este elixir no puede cambiar esa colección ahora';

  @override
  String get elixirWrongSet => 'Este elixir es de otro conjunto';

  @override
  String get elixirNotOwned => 'No tienes este elixir';

  @override
  String collectionUntil(String state, String left) {
    return 'Hasta $state: $left';
  }

  @override
  String get collectionLeftSoon => 'menos de un minuto';

  @override
  String get collectionCondGenNew => 'new';

  @override
  String get collectionCondGenWorn => 'worn';

  @override
  String get collectionCondGenTired => 'tired';

  @override
  String get collectionCondGenShabby => 'shabby';

  @override
  String get collectionCondGenVintage => 'vintage';
}
