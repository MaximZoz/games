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
    // Свой канал, не пакет sign_in_with_apple: его Swift-регистрация на iOS
    // молча не вешает method channel (MissingPluginException).
    if let registrar = self.registrar(forPlugin: "ZozuAppleSignIn") {
      ZozuAppleSignIn.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Системный лист Apple ID. Канал: com.zozugames/apple_sign_in
final class ZozuAppleSignIn: NSObject, FlutterPlugin, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
  private let registrar: FlutterPluginRegistrar
  private var pending: FlutterResult?
  private var controller: ASAuthorizationController?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.zozugames/apple_sign_in",
      binaryMessenger: registrar.messenger()
    )
    let instance = ZozuAppleSignIn(registrar: registrar)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
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
      auth.performRequests()
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    if let window = registrar.viewController?.view.window {
      return window
    }
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows where window.isKeyWindow {
        return window
      }
    }
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      if let window = windowScene.windows.first {
        return window
      }
    }
    return ASPresentationAnchor()
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
    finish([
      "identityToken": token,
      "email": credential.email ?? "",
      "givenName": credential.fullName?.givenName ?? "",
      "familyName": credential.fullName?.familyName ?? "",
    ])
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    let ns = error as NSError
    if ns.code == ASAuthorizationError.canceled.rawValue {
      finish(nil)
      return
    }
    finish(FlutterError(code: "apple_auth", message: error.localizedDescription, details: ns.domain))
  }

  private func finish(_ value: Any?) {
    let callback = pending
    pending = nil
    controller = nil
    callback?(value)
  }
}
