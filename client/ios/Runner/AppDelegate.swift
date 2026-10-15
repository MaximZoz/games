import AuthenticationServices
import Flutter
import UIKit

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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
  // binaryMessenger в Flutter 3.27 не Optional: guard let не компилируется.
  let messenger = controller.binaryMessenger
  ZozuAppleSignIn.register(messenger: messenger)
  ZozuSystemAuth.register(messenger: messenger)
  ZozuSessionStore.register(messenger: messenger)
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
