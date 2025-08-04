import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self
    Messaging.messaging().delegate = self
      
    let authOptions : UNAuthorizationOptions = [.alert,.sound,.badge]
    UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { granted, error in
            if granted {
              DispatchQueue.main.async {
                // Only register for remote notifications after permission is granted
                UIApplication.shared.registerForRemoteNotifications()
              }
            }
            if let error = error {
              print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ Handle APNs token and pass to Firebase
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    Messaging.messaging().apnsToken = deviceToken
    print("Device token: \(deviceToken)")
    print("Device Token (): \(String(describing: Messaging.messaging().apnsToken))")

    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("APNs Token: \(token)")
  }
    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

  // ✅ Firebase FCM token updated
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("FCM Token: \(fcmToken ?? "")")
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
