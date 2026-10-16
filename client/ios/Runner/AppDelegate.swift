import AuthenticationServices
import FirebaseCore
import FirebaseMessaging
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Канал нельзя вешать здесь: при UIScene registrarForPlugin попадает
    // на launch engine, который storyboard-контроллер выбрасывает.
    // Живой messenger — в SceneDelegate / didBecomeActive.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // UIScene кладёт холодный старт в connectionOptions, а тап по уже
    // живому приложению — только сюда. Firebase этот вызов иногда не видит.
    ZozuPush.rememberTap(response.notification.request.content.userInfo)
    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Токен приходит в AppDelegate, а Dart живёт в storyboard-engine.
    // Без этой копии getToken() на iPhone не получает APNs и пуш не регистрируется.
    ZozuPush.capture(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}

/// APNs-токен дожидается Firebase.initializeApp (plist может подключиться позже).
enum ZozuPush {
  static var apnsToken: Data?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.zozugames/push",
      binaryMessenger: messenger
    )
    self.channel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "firebaseReady":
        apply()
        result(nil)
      case "takeTap":
        let tap = pendingTap
        pendingTap = nil
        result(tap)
      case "clearDelivered":
        let args = call.arguments as? [String: Any] ?? [:]
        let tag = (args["tag"] as? String) ?? ""
        let prefix = (args["prefix"] as? String) ?? ""
        let all = (args["all"] as? Bool) ?? false
        let keep = (args["keep"] as? [Any])?.compactMap { $0 as? String } ?? []
        let tags = (args["tags"] as? [Any])?.compactMap { $0 as? String } ?? []
        clearDelivered(tag: tag, prefix: prefix, all: all, keep: keep, tags: tags)
        result(nil)
      case "setBadge":
        let args = call.arguments as? [String: Any] ?? [:]
        let count = (args["count"] as? NSNumber)?.intValue ?? 0
        setBadge(count)
        result(nil)
      case "refreshBadge":
        refreshBadgeFromDelivered()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static var channel: FlutterMethodChannel?
  static var pendingTap: [String: String]?

  static func rememberTap(_ userInfo: [AnyHashable: Any]) {
    var out: [String: String] = [:]
    func put(_ key: String, _ raw: Any?) {
      if out[key] != nil { return }
      let text: String
      switch raw {
      case let value as String:
        text = value.trimmingCharacters(in: .whitespacesAndNewlines)
      case let value as NSNumber:
        text = value.stringValue
      default:
        return
      }
      if !text.isEmpty {
        out[key] = text
      }
    }
    for key in ["url", "tag", "chat_id", "title", "body", "payload", "game_type", "lobby_id"] {
      put(key, userInfo[key])
    }
    put("url", userInfo["gcm.notification.url"])
    if let aps = userInfo["aps"] as? [AnyHashable: Any] {
      put("tag", aps["thread-id"])
      if let alert = aps["alert"] as? [AnyHashable: Any] {
        put("title", alert["title"])
        put("body", alert["body"])
      } else {
        put("body", aps["alert"])
      }
    }
    if out.isEmpty { return }
    pendingTap = out
    guard let channel = channel else { return }
    channel.invokeMethod("notificationTap", arguments: out) { result in
      let missed = result is FlutterError
        || (result as? NSObject) == FlutterMethodNotImplemented
      if missed { return }
      if pendingTap == out {
        pendingTap = nil
      }
    }
  }

  static func clearDelivered(
    tag: String,
    prefix: String,
    all: Bool,
    keep: [String] = [],
    tags: [String] = []
  ) {
    let center = UNUserNotificationCenter.current()
    if all {
      center.removeAllDeliveredNotifications()
      setBadge(0)
      return
    }
    let keepSet = Set(keep)
    let dropTags = Set(tags)
    center.getDeliveredNotifications { notes in
      let ids = notes.compactMap { note -> String? in
        let thread = note.request.content.threadIdentifier
        let info = note.request.content.userInfo
        let infoTag = (info["tag"] as? String) ?? ""
        let keys = [thread, infoTag].filter { !$0.isEmpty }
        if keys.isEmpty { return nil }
        if keys.contains(where: { keepSet.contains($0) }) { return nil }
        let matchesTag = (!tag.isEmpty && keys.contains(tag))
          || keys.contains { dropTags.contains($0) }
        let matchesPrefix = !prefix.isEmpty && keys.contains { $0.hasPrefix(prefix) }
        if matchesTag || matchesPrefix {
          return note.request.identifier
        }
        return nil
      }
      if !ids.isEmpty {
        center.removeDeliveredNotifications(withIdentifiers: ids)
      }
    }
  }

  static func setBadge(_ count: Int) {
    let value = max(0, count)
    DispatchQueue.main.async {
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(value) { _ in }
      } else {
        UIApplication.shared.applicationIconBadgeNumber = value
      }
    }
  }

  static func refreshBadgeFromDelivered() {
    UNUserNotificationCenter.current().getDeliveredNotifications { notes in
      setBadge(notes.count)
    }
  }

  static func capture(_ token: Data) {
    apnsToken = token
    apply()
  }

  static func apply() {
    guard let token = apnsToken else { return }
    guard FirebaseApp.app() != nil else { return }
    #if DEBUG
    Messaging.messaging().setAPNSToken(token, type: .sandbox)
    #else
    Messaging.messaging().setAPNSToken(token, type: .prod)
    #endif
  }
}

func attachZozuAuthChannels() {
  guard let controller = zozuFlutterController() else { return }
  registerZozuLivePlugins(on: controller)
}

/// Storyboard создаёт свой FlutterViewController после didFinishLaunching.
/// GeneratedPluginRegistrant в AppDelegate попадает в пустой registrar
/// (AppDelegate.window ещё nil) — SharedPreferences молчит: сессия не
/// переживает перезапуск, чекбоксы не пишутся, покупка ждёт getInstance.
func registerZozuLivePlugins(on controller: FlutterViewController) {
  if !controller.hasPlugin("SharedPreferencesPlugin") {
    GeneratedPluginRegistrant.register(with: controller)
  }
  // Xcode 26: binaryMessenger — non-optional `any FlutterBinaryMessenger`.
  // guard let здесь не компилируется.
  let messenger = controller.binaryMessenger
  ZozuAppleSignIn.register(messenger: messenger)
  ZozuSystemAuth.register(messenger: messenger)
  ZozuSessionStore.register(messenger: messenger)
  ZozuPush.register(messenger: messenger)
}

/// Живой FlutterViewController из storyboard. Плагины вешаем в awakeFromNib,
/// до launchEngine в viewDidLoad — иначе первый getInstance уже ушёл в пустоту.
final class ZozuFlutterViewController: FlutterViewController {
  override func awakeFromNib() {
    super.awakeFromNib()
    registerZozuLivePlugins(on: self)
  }
}

/// Сессия в UserDefaults напрямую, без плагина shared_preferences.
/// Канал: com.zozugames/session_store
final class ZozuSessionStore: NSObject {
  static let accessKey = "zozu.session.access_token"
  static let refreshKey = "zozu.session.refresh_token"
  static let userKey = "zozu.session.user"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.zozugames/session_store",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard
      switch call.method {
      case "read":
        result([
          "access_token": defaults.string(forKey: accessKey) ?? "",
          "refresh_token": defaults.string(forKey: refreshKey) ?? "",
          "user": defaults.string(forKey: userKey) ?? "",
        ])
      case "write":
        let args = call.arguments as? [String: Any] ?? [:]
        defaults.set((args["access_token"] as? String) ?? "", forKey: accessKey)
        defaults.set((args["refresh_token"] as? String) ?? "", forKey: refreshKey)
        defaults.set((args["user"] as? String) ?? "", forKey: userKey)
        result(true)
      case "clear":
        defaults.removeObject(forKey: accessKey)
        defaults.removeObject(forKey: refreshKey)
        defaults.removeObject(forKey: userKey)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

func zozuFlutterController() -> FlutterViewController? {
  let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
  let ordered = scenes.sorted { lhs, _ in lhs.activationState == .foregroundActive }
  for scene in ordered {
    for window in scene.windows {
      if let controller = window.rootViewController as? FlutterViewController {
        return controller
      }
    }
  }
  return nil
}

enum ZozuWindow {
  static func current() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let ordered = scenes.sorted { lhs, _ in lhs.activationState == .foregroundActive }
    for scene in ordered {
      if let window = scene.windows.first(where: { $0.isKeyWindow }) {
        return window
      }
    }
    for scene in ordered {
      if let window = scene.windows.first(where: { !$0.isHidden }) {
        return window
      }
    }
    return ordered.first?.windows.first
  }
}

/// Системный лист Apple ID. Канал: com.zozugames/apple_sign_in
final class ZozuAppleSignIn: NSObject, FlutterPlugin, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  static let shared = ZozuAppleSignIn()
  private var pending: FlutterResult?
  private var controller: ASAuthorizationController?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.zozugames/apple_sign_in",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      shared.handle(call, result: result)
    }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    register(messenger: registrar.messenger())
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(true)
    case "signIn":
      if pending != nil {
        result(FlutterError(code: "in_progress", message: "Sign in with Apple already running", details: nil))
        return
      }
      pending = result
      let request = ASAuthorizationAppleIDProvider().createRequest()
      request.requestedScopes = [.fullName, .email]
      let auth = ASAuthorizationController(authorizationRequests: [request])
      auth.delegate = self
      auth.presentationContextProvider = self
      controller = auth
      // Синхронный performRequests из method channel часто не показывает лист.
      DispatchQueue.main.async {
        auth.performRequests()
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    if let window = ZozuWindow.current() {
      return window
    }
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    if let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first {
      let window = UIWindow(windowScene: scene)
      window.frame = scene.coordinateSpace.bounds
      window.makeKeyAndVisible()
      return window
    }
    return UIWindow()
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
      finish(FlutterError(code: "no_credential", message: "Sign in with Apple: no credential", details: nil))
      return
    }
    let token = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) } ?? ""
    if token.isEmpty {
      finish(FlutterError(code: "empty_token", message: "Sign in with Apple: empty identity token", details: nil))
      return
    }
    finish([
      "identityToken": token,
      "email": credential.email ?? "",
      "givenName": credential.fullName?.givenName ?? "",
      "familyName": credential.fullName?.familyName ?? "",
    ])
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    let ns = error as NSError
    if ns.domain == ASAuthorizationError.errorDomain && ns.code == ASAuthorizationError.canceled.rawValue {
      finish(nil)
      return
    }
    let message = "\(error.localizedDescription) (\(ns.domain) \(ns.code))"
    finish(FlutterError(code: "apple_auth", message: message, details: ns.domain))
  }

  private func finish(_ value: Any?) {
    let callback = pending
    pending = nil
    controller = nil
    callback?(value)
  }
}

/// Системный лист Google (ASWebAuthenticationSession). Канал: com.zozugames/system_auth
/// Нативный GoogleSignIn на iOS без iOS OAuth client сразу падает, а внешний Safari
/// открывал сайт. Лист остаётся в приложении и закрывается на zozugames(-dev)://.
final class ZozuSystemAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = ZozuSystemAuth()
  private var session: ASWebAuthenticationSession?
  private var pending: FlutterResult?
  private var generation = 0

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.zozugames/system_auth",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      shared.handle(call, result: result)
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      if pending != nil {
        result(FlutterError(code: "in_progress", message: "Sign-in sheet already running", details: nil))
        return
      }
      let args = call.arguments as? [String: Any]
      let rawURL = (args?["url"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let scheme = (args?["callbackScheme"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard let url = URL(string: rawURL), url.scheme == "https" || url.scheme == "http" else {
        result(FlutterError(code: "bad_url", message: "Sign-in sheet: bad url", details: nil))
        return
      }
      guard scheme == "zozugames" || scheme == "zozugames-dev" else {
        result(FlutterError(code: "bad_scheme", message: "Sign-in sheet: bad callback scheme", details: nil))
        return
      }
      generation += 1
      let generationAtStart = generation
      pending = result
      let session = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { _, error in
        if generationAtStart != self.generation { return }
        if let error = error as NSError? {
          if error.domain == ASWebAuthenticationSessionError.errorDomain &&
            error.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
            self.finish(false)
            return
          }
          self.finish(FlutterError(
            code: "auth_session",
            message: error.localizedDescription,
            details: "\(error.domain) \(error.code)"
          ))
          return
        }
        self.finish(true)
      }
      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = false
      self.session = session
      if !session.start() {
        finish(FlutterError(code: "start_failed", message: "Sign-in sheet did not start", details: nil))
      }
    case "cancel":
      generation += 1
      let active = session
      session = nil
      let callback = pending
      pending = nil
      active?.cancel()
      callback?(false)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    if let window = ZozuWindow.current() {
      return window
    }
    return UIWindow()
  }

  private func finish(_ value: Any?) {
    let callback = pending
    pending = nil
    session = nil
    callback?(value)
  }
}
