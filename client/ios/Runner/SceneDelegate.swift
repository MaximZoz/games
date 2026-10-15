import Flutter
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  // Scene-based iOS не зовёт AppDelegate.openURL — без этого
  // google_sign_in зависает на лоадере после выбора аккаунта.
  func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    guard let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate
    else { return }
    for context in URLContexts {
      _ = appDelegate.application(
        UIApplication.shared,
        open: context.url,
        options: [:]
      )
    }
  }
}
