import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Zozu Games';

  @override
  String get navHome => 'Início';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navFriends => 'Amigos';

  @override
  String get navChats => 'Chats';

  @override
  String get navGames => 'Jogos';

  @override
  String get navSettings => 'Configurações';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Padrão do sistema';

  @override
  String get settingsAddBotsTitle => 'Adicionar bots após 30 s';

  @override
  String get settingsAddBotsSubtitle => 'No matchmaking: se não houver adversário em 30 segundos, o jogo começa com um bot (aposta volta a 1 bronze)';

  @override
  String get settingsOfflineModeTitle => 'Modo de rede';

  @override
  String get settingsOfflineModeSubtitle => 'Offline: jogue imediatamente contra um bot, sem apostas nem recompensas, sem chats nem amigos. As compras são salvas e aplicadas no modo online. Online — quando há internet ou pela configuração do usuário.';

  @override
  String get settingsModeOnline => 'Online';

  @override
  String get settingsModeOffline => 'Offline';

  @override
  String get gamesAlternateStartsHint => 'Em turnos quem começa a partida';

  @override
  String get rulesAlternateStarts => 'Quem joga primeiro alterna de partida para partida.';

  @override
  String get offlineBadgeTooltip => 'Modo offline';

  @override
  String get offlineModePopupTitle => 'Modo offline';

  @override
  String get offlineModePopupBody => 'O modo offline está ativo. Jogue contra um bot sem apostas nem recompensas. Chats, amigos e lobby ficam ocultos. As compras são aplicadas no modo online.';

  @override
  String get offlineModePopupSettings => 'Configurações';

  @override
  String get gamesPlay => 'Jogar';

  @override
  String get offlineGameTitle => 'Jogo contra um bot';

  @override
  String get offlineGameHint => 'Sem apostas nem recompensas · só offline';

  @override
  String get offlineBotWon => 'O bot venceu';

  @override
  String get offlineBotThinking => 'O bot está pensando…';

  @override
  String get offlinePlayAgain => 'De novo';

  @override
  String offlineBotName(int n) {
    return 'Bot $n';
  }

  @override
  String get durakActionTake => 'Pegar';

  @override
  String get durakActionAll => 'Todas';

  @override
  String get durakActionDone => 'Pronto';

  @override
  String get durakActionBito => 'Beat';

  @override
  String get durakHintDefend => 'Defenda';

  @override
  String get durakHintDefendOrTransfer => 'Defenda ou transfira';

  @override
  String get durakHintOpponentDefends => 'Oponente está defendendo';

  @override
  String get durakHintThrowInFirst => 'Jogue cartas (máx. 5 na primeira batida)';

  @override
  String get durakHintThrowIn => 'Jogue cartas ou aguarde a defesa';

  @override
  String get durakHintOpponentThrows => 'Oponente está jogando';

  @override
  String get durakHintTakeFollow => 'Jogue após pegar ou toque «Pronto»';

  @override
  String get durakHintOpponentTakeFollow => 'Oponente pode jogar após pegar';

  @override
  String get durakHintBito => 'Jogue uma carta ou diga «Bito»';

  @override
  String get durakHintOpponentBito => 'Oponente joga ou diz «Bito»';

  @override
  String get durakHintYourAttack => 'Sua vez — ataque';

  @override
  String get durakHintOpponentAttack => 'Oponente está atacando';

  @override
  String get durakHintYouLost => 'Você perdeu — você é o durak';

  @override
  String get durakHintDrawAllOut => 'Empate — todos saíram';

  @override
  String get durakHintYouFinished => 'Você saiu — aguardando o fim';

  @override
  String get shopPurchaseQueued => 'Compra salva — será aplicada no modo online';

  @override
  String shopPurchaseApplied(String title) {
    return '$title — compra aplicada';
  }

  @override
  String shopPurchaseRejected(String title, String reason) {
    return '$title — compra não aplicada: $reason';
  }

  @override
  String get settingsFriendsOnlyTitle => 'Mensagens só de amigos';

  @override
  String get settingsFriendsOnlySubtitle => 'Quem não é amigo só pode enviar emojis. Se houver spam, bloqueie temporariamente o usuário.';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsPushChat => 'Chat';

  @override
  String get settingsPushFriends => 'Amigos';

  @override
  String get settingsPushGames => 'Jogos';

  @override
  String get settingsPushRewards => 'Recompensas';

  @override
  String settingsAppVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get appUpdateTitle => 'Atualização disponível';

  @override
  String get appUpdateBody => 'Uma nova versão do app está disponível. Atualize para continuar.';

  @override
  String get appUpdateWhatsNew => 'Novidades';

  @override
  String get appUpdateOk => 'Atualizar';

  @override
  String get appUpdateLaterBanner => 'Atualizaremos o app após este jogo';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginSubtitle => 'Digite o e-mail ou nome de usuário e a senha';

  @override
  String get loginEmailLabel => 'E-mail ou nome de usuário';

  @override
  String get loginPasswordLabel => 'Senha';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginNoAccount => 'Não tem conta? Cadastre-se';

  @override
  String get loginEmailRequired => 'Digite o e-mail ou nome de usuário';

  @override
  String get loginPasswordRequired => 'Digite a senha';

  @override
  String get loginTooltip => 'Entrar';

  @override
  String get logoutTooltip => 'Sair';

  @override
  String get registerTitle => 'Cadastrar';

  @override
  String get registerSubtitle => 'Crie uma conta para jogar';

  @override
  String get registerNameLabel => 'Nome (usuário)';

  @override
  String get registerEmailLabel => 'E-mail';

  @override
  String get registerPasswordLabel => 'Senha';

  @override
  String get registerSubmit => 'Cadastrar';

  @override
  String get registerHaveAccount => 'Já tem conta? Entrar';

  @override
  String get registerNameRequired => 'Digite um nome';

  @override
  String get registerNameNoSpaces => 'O nome não pode ter espaços';

  @override
  String get registerNameMax => 'Máximo de 20 caracteres';

  @override
  String get registerNameHint => 'Até 20 caracteres';

  @override
  String get registerEmailRequired => 'Digite o e-mail';

  @override
  String get registerEmailInvalid => 'E-mail inválido';

  @override
  String get registerPasswordHint => 'Pelo menos 6 caracteres';

  @override
  String get registerPasswordMin => 'A senha deve ter pelo menos 6 caracteres';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonReply => 'Responder';

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonRetry => 'Tentar de novo';

  @override
  String get commonLoading => 'Carregando…';

  @override
  String get commonError => 'Erro';

  @override
  String get commonOnline => 'online';

  @override
  String get commonOffline => 'offline';

  @override
  String get commonOnlineCap => 'Online';

  @override
  String get commonUser => 'Usuário';

  @override
  String get commonPlayer => 'Jogador';

  @override
  String get commonAboutMe => 'Sobre mim';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonAccept => 'Aceitar';

  @override
  String get commonDecline => 'Recusar';

  @override
  String get commonCreating => 'Criando…';

  @override
  String get commonSearching => 'Buscando…';

  @override
  String get commonInsufficientCoins => 'Moedas insuficientes';

  @override
  String get commonNotFound => 'Não encontrado';

  @override
  String get commonServerErrorShort => 'Erro do servidor';

  @override
  String get commonForbidden => 'Acesso negado';

  @override
  String get commonUserBlocked => 'Usuário bloqueado';

  @override
  String get commonUserNotFound => 'Usuário não encontrado';

  @override
  String get commonGenericError => 'Algo deu errado. Tente novamente.';

  @override
  String get timeJustNow => 'agora mesmo';

  @override
  String get timeYesterday => 'ontem';

  @override
  String timeMinutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'há $count d';
  }

  @override
  String get timeWeekAgo => 'há uma semana';

  @override
  String timeWeeksAgo(int count) {
    return 'há $count sem.';
  }

  @override
  String get timeMonthAgo => 'há um mês';

  @override
  String timeMonthsAgo(int count) {
    return 'há $count mês.';
  }

  @override
  String get timeYearAgo => 'há um ano';

  @override
  String timeYearsAgo(int count) {
    return 'há $count a.';
  }

  @override
  String get weekdaySun => 'Dom';

  @override
  String get weekdayMon => 'Seg';

  @override
  String get weekdayTue => 'Ter';

  @override
  String get weekdayWed => 'Qua';

  @override
  String get weekdayThu => 'Qui';

  @override
  String get weekdayFri => 'Sex';

  @override
  String get weekdaySat => 'Sáb';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Fev';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Set';

  @override
  String get monthOct => 'Out';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get homeAchievements => 'Conquistas';

  @override
  String get homeAchievementsSubtitle => 'Seus resultados de jogo';

  @override
  String get homeAchievementsRewards => 'Recompensas disponíveis para resgatar';

  @override
  String get homeCoins => 'Moedas';

  @override
  String get homeCoinsSubtitle => 'Saldo e recompensas';

  @override
  String get homeCoinsDailyReward => 'Recompensa diária de login disponível';

  @override
  String get homeItems => 'Itens';

  @override
  String get homeItemsInventory => 'Seu inventário';

  @override
  String get homeItemsGifted => 'Alguém te presenteou com uma coleção';

  @override
  String get homeItemsIncome => 'Rendimento da coleção pronto para resgatar';

  @override
  String get homeShop => 'Loja';

  @override
  String get homeShopSubtitle => 'Emojis, apostas, coleções';

  @override
  String get gamesTitle => 'Jogos';

  @override
  String get gamesFindMatch => 'Encontrar jogo';

  @override
  String get gamesMyTurn => 'Sua vez';

  @override
  String get gamesWaiting => 'Aguardando';

  @override
  String get gamesLobbyTab => 'Lobby';

  @override
  String get gamesTicTacToe => 'Jogo da velha';

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
  String get gamesPoker => 'Pôquer';

  @override
  String get gamesInDevelopment => 'Em desenvolvimento';

  @override
  String rulesPokerPlayers(int players) {
    return 'Jogadores: $players.';
  }

  @override
  String get rulesPokerIntro => 'Texas Hold’em. Cada jogador recebe 2 cartas fechadas; 5 cartas comunitárias vão à mesa.';

  @override
  String get rulesPokerPlay => 'Rodadas de apostas: pré-flop, flop, turn e river. Pode dar fold, call, bet ou raise.';

  @override
  String get rulesPokerWin => 'Vence a melhor mão de cinco cartas (fechadas + comunitárias), ou o último após folds.';

  @override
  String get gamesRules => 'Regras';

  @override
  String get gamesRulesTitle => 'Regras do jogo';

  @override
  String get gamesCreate => 'Criar jogo';

  @override
  String get gamesJoin => 'Entrar';

  @override
  String get gamesOpponentTurn => 'Vez do adversário';

  @override
  String get gamesCurrentGame => 'Jogo atual';

  @override
  String get gamesInvitedYou => 'Você foi convidado';

  @override
  String get gamesTurnTime => 'Tempo por turno';

  @override
  String get gamesGridSize => 'Tamanho da grade';

  @override
  String get gamesSwapSides => 'Troca de lado';

  @override
  String get gamesNoCenter => 'Sem início no centro';

  @override
  String get gamesObservation => 'Observando';

  @override
  String get gamesObservationHint => 'Você pode assistir até o fim do jogo';

  @override
  String get gamesFinishCurrentFirst => 'Termine seu jogo atual primeiro';

  @override
  String get gamesVariantClassic => 'Clássico';

  @override
  String get gamesVariantGomoku => 'Gomoku';

  @override
  String get gamesVariantUltimate => 'Ultimate';

  @override
  String get gamesVariantMulti3 => '3 jogadores';

  @override
  String get gamesVariantMulti4 => '4 jogadores';

  @override
  String get gamesDurakModePodkidnoi => 'Apoio';

  @override
  String get gamesDurakModePerevodnoi => 'Transferência';

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
    return 'Jogadores: $players. Baralho: $deck.';
  }

  @override
  String get rulesDurakOfflineBot => 'Jogue contra um bot, sem apostas nem limite de tempo.';

  @override
  String get rulesDurakAttack => 'O atacante joga cartas; o defensor cobre (mesmo naipe mais alto, ou um trunfo). Um trunfo só é coberto por um trunfo maior.';

  @override
  String get rulesDurakBeat => 'Quando todas as cartas estão cobertas, o atacante diz «Bito» e vão para o descarte. Senão o defensor leva tudo da mesa.';

  @override
  String get rulesDurakLoser => 'Perde quem fica com cartas no fim — o «durak».';

  @override
  String lobbyPlayersCount(int count, int maxPlayers) {
    return 'Jogadores $count/$maxPlayers';
  }

  @override
  String lobbyNamed(String name) {
    return 'Lobby $name';
  }

  @override
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Jogo privado';

  @override
  String get lobbySearchingOpponent => 'Procurando adversário…';

  @override
  String lobbyPlayersSearching(int count) {
    return 'Procurando este jogo: $count';
  }

  @override
  String get lobbyWaitingJoin => 'Aguardando alguém tocar em “Encontrar jogo” ou “Entrar”';

  @override
  String get lobbyInviteTitle => 'Convite para jogar';

  @override
  String get lobbyInvitedToPlay => 'Você foi convidado a jogar';

  @override
  String get lobbyEnterGame => 'Entrar no jogo';

  @override
  String get lobbyGone => 'Lobby não está mais disponível';

  @override
  String get lobbyInvite => 'Convidar';

  @override
  String get lobbyInviteSent => 'Convite enviado';

  @override
  String get lobbyCopyLink => 'Compartilhar link do jogo';

  @override
  String get lobbyLinkCopied => 'Link copiado';

  @override
  String get lobbyNoFriendsOnline => 'Nenhum amigo online. Compartilhe o link acima ou aguarde os amigos ficarem online.';

  @override
  String get gameBot => 'Bot';

  @override
  String get gameOpponent => 'Adversário';

  @override
  String get gameYouWon => 'Você ganhou!';

  @override
  String get gameYouLost => 'Você perdeu';

  @override
  String get gameYouWonOpponentLeft => 'Você ganhou — o adversário saiu';

  @override
  String get gameYouWonOpponentTimeout => 'Você ganhou — o tempo do adversário acabou';

  @override
  String get gameDraw => 'Empate';

  @override
  String get gameExitTitle => 'Sair do jogo';

  @override
  String get gameExitConfirm => 'Se sair, você perde. Sair mesmo assim?';

  @override
  String get gameStay => 'Ficar';

  @override
  String get gameLeave => 'Sair';

  @override
  String get gameSurrender => 'Desistir';

  @override
  String get gameSurrenderTitle => 'Desistir?';

  @override
  String get gameSurrenderConfirm => 'Você perde a partida e as moedas da aposta.';

  @override
  String get gameOfferDraw => 'Oferecer empate';

  @override
  String get gameOfferDrawTitle => 'Oferecer empate?';

  @override
  String get gameOfferDrawConfirm => 'Seu adversário pode aceitar ou recusar o empate.';

  @override
  String get gameAcceptDrawTitle => 'Aceitar empate?';

  @override
  String get gameAcceptDrawConfirm => 'A partida terminará empatada.';

  @override
  String get gameDrawOffered => 'O adversário oferece empate';

  @override
  String get gameConnecting => 'Conectando ao jogo…';

  @override
  String get gameWaitingOpponent => 'Aguardando adversário';

  @override
  String get gameRematchOffer => 'O adversário oferece uma revanche';

  @override
  String get gameRematchDeclined => 'O adversário recusou a revanche';

  @override
  String get gameRematch => 'Revanche';

  @override
  String get gameOtherOpponent => 'Outro adversário';

  @override
  String get gameSwapSidesAction => 'Trocar de lado';

  @override
  String get gameWriteMessage => 'Escrever uma mensagem';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'Ainda não há chats.\nToque no ícone no canto superior direito para escolher um amigo e começar a conversar.';

  @override
  String get chatsNewChat => 'Novo chat';

  @override
  String get chatsNoMessages => 'Sem mensagens';

  @override
  String get chatsClearTitle => 'Limpar conversa?';

  @override
  String get chatsClearDesc => 'O chat será excluído permanentemente.';

  @override
  String get chatsClearConfirm => 'Limpar';

  @override
  String get chatsBlockTitle => 'Bloquear este usuário?';

  @override
  String get chatsBlockDesc => 'Vocês não poderão mais se enviar mensagens. O chat e a amizade serão removidos.';

  @override
  String get chatsBlockConfirm => 'Bloquear';

  @override
  String get chatsBlockedUsers => 'Usuários bloqueados';

  @override
  String get chatsUnblock => 'Desbloquear';

  @override
  String get chatDialog => 'Chat';

  @override
  String get chatEmpty => 'Ainda não há mensagens.\nEnvie a primeira.';

  @override
  String get chatMessageHint => 'Mensagem';

  @override
  String get chatPaste => 'Colar';

  @override
  String get chatEmoji => 'Emojis';

  @override
  String get chatBuyEmojiHint => 'Compre emojis na loja na tela inicial';

  @override
  String get chatEditing => 'Editando';

  @override
  String get chatToday => 'Hoje';

  @override
  String get chatYesterday => 'Ontem';

  @override
  String get chatFriendsOnly => 'Texto só para amigos';

  @override
  String get emojiGroupEmotions => 'Emoções';

  @override
  String get emojiGroupGame => 'Jogos';

  @override
  String get emojiGroupFlags => 'Bandeiras';

  @override
  String get emojiGroupAnimals => 'Animais';

  @override
  String get emojiGroupFood => 'Comida';

  @override
  String get emojiGroupTravel => 'Viagens';

  @override
  String get emojiGroupParty => 'Celebração';

  @override
  String get emojiGroupObjects => 'Objetos';

  @override
  String get friendsTitle => 'Amigos';

  @override
  String get friendsTabFriends => 'Amigos';

  @override
  String get friendsTabIncoming => 'Recebidos';

  @override
  String get friendsTabOutgoing => 'Enviados';

  @override
  String get friendsAdd => 'Adicionar amigo';

  @override
  String get friendsRequestSent => 'Pedido enviado';

  @override
  String get friendsFindTab => 'Encontrar amigo';

  @override
  String get friendsSearchHint => 'Buscar por nome de usuário';

  @override
  String get friendsSearchPrompt => 'Use a busca para encontrar novos amigos';

  @override
  String get friendsNothingFound => 'Nada encontrado';

  @override
  String get friendsEmpty => 'Você ainda não tem amigos';

  @override
  String get friendsNoIncoming => 'Sem pedidos recebidos';

  @override
  String get friendsNoOutgoing => 'Sem pedidos enviados';

  @override
  String get friendsAlreadyFriends => 'Já são amigos';

  @override
  String get friendsRemoveTitle => 'Remover dos amigos?';

  @override
  String get friendsRemoved => 'Removido dos amigos';

  @override
  String get friendsRequestAccepted => 'Pedido aceito';

  @override
  String get friendsRequestDeclined => 'Pedido recusado';

  @override
  String get friendsRequestCancelled => 'Pedido cancelado';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSignInPrompt => 'Entre na sua conta';

  @override
  String get profileSignInHint => 'Para configurar seu perfil pessoal';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileCollections => 'Coleções';

  @override
  String get profileAge => 'Idade';

  @override
  String get profileGender => 'Gênero';

  @override
  String get profileGenderUnset => 'Não definido';

  @override
  String get profileGenderMale => 'Masculino';

  @override
  String get profileGenderFemale => 'Feminino';

  @override
  String get profileAvatar => 'Avatar';

  @override
  String get profileUploadPhoto => 'Enviar foto';

  @override
  String get profileChangePhoto => 'Trocar foto';

  @override
  String get shopTitle => 'Loja';

  @override
  String get shopEmojis => 'Emojis';

  @override
  String get shopEmojisSubtitle => 'Emojis animados para o chat';

  @override
  String get shopCollections => 'Coleções';

  @override
  String get shopCollectionsSubtitle => 'Vitrine do perfil, presentes e rendimento';

  @override
  String get shopStakes => 'Apostas';

  @override
  String get shopStakesSubtitle => 'Desbloquear apostas mais altas';

  @override
  String get inventoryTitle => 'Itens';

  @override
  String get inventoryEmpty => 'Ainda não há nada aqui — veja a loja';

  @override
  String get inventoryFrames => 'Molduras';

  @override
  String get inventoryClaim => 'Resgatar';

  @override
  String get inventorySell => 'Vender';

  @override
  String get inventoryGift => 'Presentear';

  @override
  String get messageEdited => 'editado';

  @override
  String get messageDeleted => 'Mensagem excluída';

  @override
  String get photo => 'Foto';

  @override
  String get camera => 'Câmera';

  @override
  String get gallery => 'Galeria';

  @override
  String get connectionError => 'Não foi possível conectar ao servidor.';

  @override
  String get serverError => 'Erro do servidor. Tente novamente mais tarde.';

  @override
  String get sessionExpired => 'Sessão expirada. Entre novamente.';

  @override
  String get errNoInternet => 'Sem conexão com a Internet.';

  @override
  String get errTimeout => 'A solicitação expirou. Tente novamente.';

  @override
  String get errGamesUnavailable => 'Os jogos estão temporariamente indisponíveis';

  @override
  String get errSettingsSaveFailed => 'Não foi possível salvar a configuração';

  @override
  String get errPushPermission => 'Permita notificações nas configurações do navegador ou do sistema.';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get coinBronze => 'Bronze';

  @override
  String get coinSilver => 'Prata';

  @override
  String get coinGold => 'Ouro';

  @override
  String get coinDiamond => 'Diamante';

  @override
  String get balanceZeroBronze => '0 bronze';

  @override
  String balanceBronzes(int count) {
    return '$count bronze';
  }

  @override
  String balanceSilvers(int count) {
    return '$count prata';
  }

  @override
  String balanceGolds(int count) {
    return '$count ouro';
  }

  @override
  String balanceDiamonds(int count) {
    return '$count diamantes';
  }

  @override
  String balancePerDay(String amount) {
    return '$amount/dia';
  }

  @override
  String get balanceAbbrBronze => 'br';

  @override
  String get balanceAbbrSilver => 'pr.';

  @override
  String get balanceAbbrGold => 'ou.';

  @override
  String get commonBackHome => 'Voltar ao início';

  @override
  String get commonCopied => 'Copiado';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonTryLater => 'Tente novamente mais tarde.';

  @override
  String get commonTryRefresh => 'Tente atualizar a página.';

  @override
  String get coinsTitle => 'Moedas';

  @override
  String get coinsLoginReward => 'Recompensa de login';

  @override
  String get coinsLoginAvailableToday => 'Recompensa de hoje disponível';

  @override
  String get coinsLoginStreak => 'Sequência diária de logins';

  @override
  String get coinsFriendReward => 'Recompensa por amigo';

  @override
  String coinsFriendRewardHint(String amount) {
    return '+$amount por registo através do seu link';
  }

  @override
  String get coinsLoadRewardsFailed => 'Não foi possível carregar as recompensas';

  @override
  String get coinsClaimReward => 'Receber recompensa';

  @override
  String get coinsAlreadyClaimed => 'Já recebida';

  @override
  String coinsStreakToday(int done, int target) {
    return '$done/$target · hoje';
  }

  @override
  String coinsStreakOneDayLeft(int done, int target) {
    return '$done/$target · falta 1 dia';
  }

  @override
  String coinsStreakDaysLeft(int done, int target, int remaining) {
    return '$done/$target · faltam $remaining';
  }

  @override
  String get coinsInviteFriend => 'Convidar um amigo';

  @override
  String coinsInviteHint(String amount) {
    return '+$amount por cada pessoa que se registar com o seu link';
  }

  @override
  String get coinsCopyLink => 'Copiar link';

  @override
  String get coinsHowItWorks => 'Como funciona';

  @override
  String get coinsHowStep1 => 'Copie o link e envie a um amigo';

  @override
  String get coinsHowStep2 => 'O amigo regista-se com esse link';

  @override
  String coinsHowStep3(String amount) {
    return 'Recebe $amount';
  }

  @override
  String get achievementsTitle => 'Conquistas';

  @override
  String achievementsProgress(String progress) {
    return 'Progresso: $progress';
  }

  @override
  String get achievementsFrameClaimed => 'Moldura obtida';

  @override
  String get achievementsClaimed => 'Obtido';

  @override
  String get achievementsOpenFrame => 'Abrir moldura';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Tem a certeza de que quer remover $name dos amigos?';
  }

  @override
  String get friendsRemoveConfirmAction => 'Remover';

  @override
  String get friendsRemove => 'Remover dos amigos';

  @override
  String get friendsAcceptRequest => 'Aceitar pedido';

  @override
  String get friendsDeclineRequest => 'Recusar pedido';

  @override
  String get friendsCancelRequest => 'Cancelar pedido';

  @override
  String get friendsSendRequest => 'Enviar pedido de amizade';

  @override
  String get friendsRequestAlreadySent => 'Pedido já enviado';

  @override
  String get friendsIncomingStatus => 'Pedido recebido';

  @override
  String get friendsOutgoingStatus => 'Pedido enviado';

  @override
  String get friendsNotFriends => 'Não são amigos';

  @override
  String get friendsCollapseSearch => 'Recolher pesquisa';

  @override
  String get friendsExpandSearch => 'Mostrar pesquisa';

  @override
  String get friendsLoadFailed => 'Não foi possível carregar os amigos';

  @override
  String friendsSince(String date) {
    return 'Amigos desde: $date';
  }

  @override
  String friendsIncomingAt(String date) {
    return 'Pedido recebido: $date';
  }

  @override
  String friendsOutgoingAt(String date) {
    return 'Pedido enviado: $date';
  }

  @override
  String get userInfoTitle => 'Informações do utilizador';

  @override
  String profileAgeYears(int age) {
    return '$age anos';
  }

  @override
  String get shopBuy => 'Comprar';

  @override
  String get shopBuyTitle => 'Comprar?';

  @override
  String get shopBuyStakeTitle => 'Comprar aposta?';

  @override
  String get shopBuyEmojiTitle => 'Comprar emoji?';

  @override
  String get shopBuyCollectionTitle => 'Comprar coleção?';

  @override
  String shopPrice(String price) {
    return 'Preço: $price';
  }

  @override
  String get shopOwned => 'Comprado';

  @override
  String get shopEmpty => 'Ainda vazio';

  @override
  String shopPurchased(String title) {
    return '$title comprado';
  }

  @override
  String get shopEmojiUses => 'Recebe: 10 utilizações';

  @override
  String shopEmojiBought(String title) {
    return '$title: +10 utilizações';
  }

  @override
  String shopEmojiPriceUses(String price) {
    return '$price · 10 utilizações';
  }

  @override
  String get shopBuyTen => 'Comprar · 10 un.';

  @override
  String shopDailyIncome(String amount) {
    return 'Rendimento: $amount';
  }

  @override
  String get shopBuyOnce => 'Compra única';

  @override
  String get shopSellRefund => 'Vender devolve 80% do custo';

  @override
  String shopCollectionAdded(String title) {
    return '$title adicionado ao perfil';
  }

  @override
  String shopSetBonus(int percent) {
    return 'bónus do conjunto +$percent%';
  }

  @override
  String get shopSetComplete => 'Completo';

  @override
  String shopSetProgress(int owned, int total) {
    return 'Recolhido · $owned/$total';
  }

  @override
  String get inventorySellTitle => 'Vender?';

  @override
  String inventorySellDesc(String amount) {
    return 'Receberá $amount';
  }

  @override
  String inventorySold(String amount) {
    return 'Vendido: +$amount';
  }

  @override
  String get inventoryNeedFriends => 'Adicione amigos primeiro';

  @override
  String get inventoryGiftTitle => 'Oferecer coleção?';

  @override
  String inventoryGiftDesc(String title, String name) {
    return 'Oferecer «$title» a $name?';
  }

  @override
  String inventoryGifted(String title) {
    return 'Oferecido: $title';
  }

  @override
  String get inventoryGiftAlreadyOwns => 'O jogador já possui este item';

  @override
  String get inventoryGiftSelf => 'Você não pode presentear a si mesmo';

  @override
  String get inventoryGiftNotOwned => 'Este item não está no seu inventário';

  @override
  String get inventoryLoadFailed => 'Não foi possível carregar os itens';

  @override
  String get inventoryNoCollections => 'Sem coleções — compre na loja';

  @override
  String get inventoryNoEmojis => 'Sem emojis — compre na loja';

  @override
  String get inventoryNoFrames => 'Sem molduras — ganhe 10 jogos de liga (conquistas)';

  @override
  String get inventoryNoStakes => 'Sem apostas compradas';

  @override
  String inventoryEmojiLeft(int count) {
    return 'Restam $count';
  }

  @override
  String inventoryIncomeReady(String amount) {
    return 'Rendimento: +$amount';
  }

  @override
  String inventoryIncomeTomorrow(String amount) {
    return 'Rendimento amanhã: $amount';
  }

  @override
  String get inventoryIncomeReadyLabel => 'Pronto';

  @override
  String get inventoryIncomeTomorrowLabel => 'Amanhã';

  @override
  String inventoryStakeGold(String amount) {
    return 'Pode apostar $amount de ouro';
  }

  @override
  String inventoryStakeSilver(String amount) {
    return 'Pode apostar $amount de prata';
  }

  @override
  String inventoryClaimedAmount(String amount) {
    return 'Recebido +$amount';
  }

  @override
  String get chatsLoadFailed => 'Não foi possível carregar os chats';

  @override
  String get chatsLoadListFailed => 'Não foi possível carregar a lista';

  @override
  String get chatsBlockedEmpty => 'A lista está vazia';

  @override
  String chatsBlockedAt(String date) {
    return 'Bloqueado: $date';
  }

  @override
  String get chatsCreateFailed => 'Não foi possível criar o chat';

  @override
  String get chatsNeedFriendsFirst => 'Adicione amigos primeiro; depois pode abrir um chat.';

  @override
  String get chatsFriendsNotFound => 'Amigos não encontrados';

  @override
  String get chatsFindFriendHint => 'Encontrar amigo pelo nick';

  @override
  String get chatsSelectChat => 'Selecione um chat';

  @override
  String get chatsSelectHint => 'Escolha uma conversa na lista à esquerda';

  @override
  String get chatEditFailed => 'Não foi possível editar a mensagem';

  @override
  String get chatSendFailed => 'Não foi possível enviar a mensagem';

  @override
  String get chatDeleteFailed => 'Não foi possível eliminar a mensagem';

  @override
  String get chatEmojiSendFailed => 'Não foi possível enviar o emoji';

  @override
  String get chatLoadFailed => 'Não foi possível carregar as mensagens';

  @override
  String get chatBackToGame => 'Voltar ao jogo';

  @override
  String get chatBackToChats => 'Voltar aos chats';

  @override
  String get chatActions => 'Ações do chat';

  @override
  String get chatAutoTranslate => 'Tradução automática';

  @override
  String get chatScrollToEnd => 'Ir para o fim';

  @override
  String chatReplyingTo(String name) {
    return 'Em resposta a $name';
  }

  @override
  String get chatGift => 'Presente';

  @override
  String get chatCollection => 'Coleção';

  @override
  String get chatGiftCollection => 'Presente · coleção';

  @override
  String get chatThisUser => 'este utilizador';

  @override
  String get gamesLobbyLoadFailed => 'Não foi possível carregar o lobby.';

  @override
  String get gamesTapChangeStake => 'Toque para alterar a aposta';

  @override
  String get gamesTapChangeTurnTime => 'Toque para alterar o tempo por jogada';

  @override
  String get gamesTapChangeGrid => 'Toque para alterar o tamanho da grelha';

  @override
  String get gamesSwapSidesHint => 'O pode tornar-se X após a 1.ª jogada';

  @override
  String get gamesNoCenterHint => 'A primeira jogada não pode ser no centro';

  @override
  String get lobbyInviteSentShort => 'Enviado';

  @override
  String get lobbyInvitesSentWaiting => 'Convites enviados. A aguardar resposta.';

  @override
  String get lobbyLinkCopiedHint => 'Cole-o num chat ou mensagem a um amigo';

  @override
  String get lobbyCopyLinkHint => 'Copiar link para a área de transferência';

  @override
  String lobbyCreatorInvites(String name) {
    return '$name convida-o a jogar';
  }

  @override
  String gameOpponentWon(String name) {
    return '$name venceu';
  }

  @override
  String gameOpponentWonTimeout(String name) {
    return 'O tempo acabou. $name venceu';
  }

  @override
  String gameSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get adminTitle => 'Admin';

  @override
  String get tournamentsTitle => 'Torneios';

  @override
  String get profileAgeInvalid => 'Introduza uma idade de 1 a 111';

  @override
  String get profileSaveFailed => 'Não foi possível guardar o perfil';

  @override
  String get profileNameHint => 'Letras latinas, dígitos, _ até 10 caracteres';

  @override
  String get profileNameLatinOnly => 'Latin characters only';

  @override
  String get profileAgeHint => 'De 1 a 111';

  @override
  String get profileAboutHint => 'Até 100 caracteres (opcional)';

  @override
  String get profileProcessingPhoto => 'A processar foto…';

  @override
  String get profileCropTitle => 'Escolha a área do avatar';

  @override
  String get profileCropHint => 'Amplie e mova a foto';

  @override
  String get profileApply => 'Aplicar';

  @override
  String get profilePreparing => 'A preparar…';

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
    return 'Jogo da velha em um tabuleiro $grid. Em turnos; X começa.';
  }

  @override
  String rulesWin(int n) {
    return 'Vitória: alinhe $n em linha na horizontal, vertical ou diagonal.';
  }

  @override
  String get rulesNoTimeLimit => 'Sem limite de tempo por jogada.';

  @override
  String rulesTurnTime(String time) {
    return 'Tempo por jogada: $time.';
  }

  @override
  String rulesStake(String stake) {
    return 'Aposta: $stake. O jogo vale tantas moedas.';
  }

  @override
  String get rulesSwap => 'Troca de lados: O pode trocar com X após o primeiro lance de X.';

  @override
  String get rulesNoCenter => 'Sem centro: X não pode jogar no centro no primeiro lance.';

  @override
  String get collectionSetLegends => 'Lendas';

  @override
  String get collectionSetSpace => 'Espaço';

  @override
  String get collectionSetGems => 'Gemas';

  @override
  String get collectionSetParty => 'Festa';

  @override
  String get collectionSetNature => 'Natureza';

  @override
  String get collectionSetAdventures => 'Aventuras';

  @override
  String collectionCardMeta(String amount) {
    return 'Coleção · vitrine · presente · venda · +$amount';
  }

  @override
  String get coinsDayOne => 'dia';

  @override
  String get coinsDayFew => 'dias';

  @override
  String get coinsDayMany => 'dias';

  @override
  String get giftFriendTitle => 'Presentear um amigo';

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
    return '$count emojis · $price';
  }

  @override
  String get chatsExpandPanel => 'Expandir painel';

  @override
  String get chatsCollapsePanel => 'Recolher painel';

  @override
  String get chatReplySourceMissing => 'Mensagem original não encontrada';

  @override
  String shopStakeTitleSilver(int n) {
    return 'Aposta $n prata';
  }

  @override
  String shopStakeTitleGold(int n) {
    return 'Aposta $n ouro';
  }

  @override
  String shopStakeDescSilver(int n) {
    return 'Desbloqueia apostar $n de prata';
  }

  @override
  String shopStakeDescGold(int n) {
    return 'Desbloqueia apostar $n de ouro';
  }

  @override
  String get chatReplySelf => 'você mesmo';

  @override
  String get chatReplyPeer => 'ao interlocutor';

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
  String get statsTitle => 'Estatísticas';

  @override
  String get statsLoadFailed => 'Falha ao carregar as estatísticas';

  @override
  String get statsAllGames => 'Todos os jogos';

  @override
  String get statsEmptyTitle => 'Ainda não há partidas jogadas';

  @override
  String get statsEmptyHint => 'Jogue sua primeira partida para ver as estatísticas aqui.';

  @override
  String get statsWins => 'Vitórias';

  @override
  String get statsDraws => 'Empates';

  @override
  String get statsLosses => 'Derrotas';

  @override
  String get statsWinRate => 'Taxa de vitórias';

  @override
  String get statsTopWon => 'Mais vitórias contra';

  @override
  String get statsTopDrawn => 'Mais empates com';

  @override
  String get statsTopLost => 'Mais derrotas contra';

  @override
  String get statsTimePlayed => 'Tempo de jogo';

  @override
  String get statsYourScore => 'Seu placar';

  @override
  String get profileShowStats => 'Mostrar estatísticas';

  @override
  String get statsDurationZeroMinutes => '0 min';

  @override
  String get gameYouWonOpponentForfeit => 'O adversário desistiu. Você venceu!';

  @override
  String get lobbyLeaveTitle => 'Sair do lobby?';

  @override
  String get lobbyLeaveConfirm => 'O lobby será excluído após a saída. Amigos convidados receberão uma recusa.';

  @override
  String get lobbyLeave => 'Sair';

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
    return 'Você desistiu. $name venceu';
  }

  @override
  String get supportTitle => 'Suporte';

  @override
  String get supportUnavailable => 'O suporte está indisponível';

  @override
  String get supportOpenFailed => 'Não foi possível abrir o chat de suporte';

  @override
  String coinsGrantedTitle(int amount) {
    return 'Você recebeu $amount moedas';
  }

  @override
  String coinsDeductedTitle(int amount) {
    return '$amount moedas foram debitadas';
  }

  @override
  String get coinsCreditCardTitle => 'Você recebeu moedas';

  @override
  String get coinsClaim => 'Resgatar';

  @override
  String get durakActionPass => 'Passar';

  @override
  String get durakRoleTook => 'Pegou';

  @override
  String get durakRoleBeats => 'Bate';

  @override
  String get durakRoleThrowIn => 'Apoio';

  @override
  String get durakRoleTurn => 'Vez';

  @override
  String get durakRoleDefends => 'Defende';

  @override
  String get durakStatusTaking => 'Pegando';

  @override
  String get durakHintDefenderTurn => 'Vez do defensor';

  @override
  String get gameYouEliminated => 'Você saiu';

  @override
  String gameYouPlaced(int place) {
    return 'Você ficou em $placeº';
  }

  @override
  String get gameOverNeutral => 'Jogo terminado';

  @override
  String gameTurnOf(String name) {
    return 'Vez de $name';
  }

  @override
  String get chatGroupTooltip => 'Chat do grupo';

  @override
  String get lobbyChatNotReady => 'O chat do lobby ainda não está pronto';

  @override
  String get chatsGroupChat => 'Chat em grupo';

  @override
  String chatsMembersCount(int count) {
    return 'Membros: $count';
  }

  @override
  String chatsMembersShort(int count) {
    return '$count pess.';
  }

  @override
  String get chatsYouSuffix => '(você)';

  @override
  String get chatTitleDurak3 => 'Durak · 3 jogadores';

  @override
  String get chatTitleDurak4 => 'Durak · 4 jogadores';

  @override
  String get rulesTttUltimate => 'Ultimate: nove mini-tabuleiros 3×3. Uma jogada manda o oponente para esse mini-tabuleiro. Vence quem completar uma linha no meta-tabuleiro.';

  @override
  String get rulesTttMulti3 => '3 jogadores: tabuleiro 3×3, três jogadores (X, O, △). Complete uma linha com seus símbolos para vencer.';

  @override
  String get rulesTttMulti4 => '4 jogadores: tabuleiro 4×4, quatro jogadores (X, O, △, □). Complete uma linha com seus símbolos para vencer.';
}
