import Flutter
import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  /// Ссылка, которой открыли приложение, пока storyboard-engine ещё не жив.
  private var pendingOpenURLs: [URL] = []

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let response = connectionOptions.notificationResponse {
      ZozuPush.rememberTap(response.notification.request.content.userInfo)
    }
    for context in connectionOptions.urlContexts {
      pendingOpenURLs.append(context.url)
    }
    for activity in connectionOptions.userActivities {
      rememberWebURL(activity)
    }
    attachZozuAuthChannels()
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    attachZozuAuthChannels()
    ZozuPush.apply()
    // Окно storyboard иногда появляется на следующем обороте run loop.
    // Ссылку холодного старта отдаём тогда же, один раз, уже живому engine.
    DispatchQueue.main.async {
      attachZozuAuthChannels()
      ZozuPush.apply()
      self.flushPendingOpenURLs(clear: true)
    }
  }

  // Scene-based iOS не зовёт AppDelegate.openURL — без этого
  // google_sign_in зависает на лоадере после выбора аккаунта.
  func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      pendingOpenURLs.append(context.url)
    }
    flushPendingOpenURLs(clear: true)
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    rememberWebURL(userActivity)
    flushPendingOpenURLs(clear: true)
  }

  private func rememberWebURL(_ activity: NSUserActivity) {
    guard activity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = activity.webpageURL
    else { return }
    pendingOpenURLs.append(url)
  }

  private func flushPendingOpenURLs(clear: Bool) {
    guard !pendingOpenURLs.isEmpty,
          let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate
    else { return }
    let urls = pendingOpenURLs
    if clear {
      pendingOpenURLs = []
    }
    for url in urls {
      _ = appDelegate.application(
        UIApplication.shared,
        open: url,
        options: [:]
      )
    }
  }
}
