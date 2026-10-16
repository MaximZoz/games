import Flutter
import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let response = connectionOptions.notificationResponse {
      ZozuPush.rememberTap(response.notification.request.content.userInfo)
    }
    attachZozuAuthChannels()
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    attachZozuAuthChannels()
    ZozuPush.apply()
    // Окно storyboard иногда появляется на следующем обороте run loop.
    DispatchQueue.main.async {
      attachZozuAuthChannels()
      ZozuPush.apply()
    }
  }

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
