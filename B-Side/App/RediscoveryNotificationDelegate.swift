import UIKit
import UserNotifications

final class RediscoveryNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Home already exposes rediscovery; no redundant banner, sound, or custom popup.
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              response.notification.request.identifier == "sideb.dailyRediscovery",
              response.notification.request.content.userInfo["destination"] as? String == "sideb.dailyRediscovery" else {
            completionHandler()
            return
        }
        Task { @MainActor in
            DailyRediscoveryNotificationManager.shared.shouldOpenHome = true
            completionHandler()
        }
    }
}
