import UIKit
import UserNotifications

/// 全局方向锁：默认竖屏；打开「详细」横屏折线图时临时切到横屏。
/// 同时作为通知代理，让测温闹铃在 App 前台时也能弹出。
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }

    /// 前台也展示通知横幅与声音
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
