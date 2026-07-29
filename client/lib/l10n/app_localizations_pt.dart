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
  String timeMinutesAgo(Object count) {
    return 'há $count min';
  }

  @override
  String timeHoursAgo(Object count) {
    return 'há $count h';
  }

  @override
  String timeDaysAgo(Object count) {
    return 'há $count d';
  }

  @override
  String get timeWeekAgo => 'há uma semana';

  @override
  String timeWeeksAgo(Object count) {
    return 'há $count sem.';
  }

  @override
  String get timeMonthAgo => 'há um mês';

  @override
  String timeMonthsAgo(Object count) {
    return 'há $count mês.';
  }

  @override
  String get timeYearAgo => 'há um ano';

  @override
  String timeYearsAgo(Object count) {
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
  String get lobbyMatchmake => 'Lobby';

  @override
  String get lobbyPrivateGame => 'Jogo privado';

  @override
  String get lobbySearchingOpponent => 'Procurando adversário…';

  @override
  String get lobbyWaitingJoin => 'Aguardando alguém tocar em “Encontrar jogo” ou “Entrar”';

  @override
  String get lobbyInviteTitle => 'Convite para jogar';

  @override
  String get lobbyInvitedToPlay => 'Você foi convidado a jogar';

  @override
  String get lobbyEnterGame => 'Entrar no jogo';

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
  String get shopStakesSubtitle => 'Desbloquear apostas de prata';

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
}
