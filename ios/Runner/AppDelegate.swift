import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Google Maps BEFORE Firebase
    GMSServices.provideAPIKey("AIzaSyBqleh1U7Ef1RxfNpl_9C3p6J05DH3tHqM")
    
    // Configure Firebase
    FirebaseApp.configure()
    
    // Register for remote notifications (required for phone auth)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle APNs token registration
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("📱 APNs token received")
    
    // Set APNs token for Firebase Messaging (required for FCM on iOS)
    Messaging.messaging().apnsToken = deviceToken
    
    // Set APNs token for Firebase Auth (required for phone auth)
    #if DEBUG
    Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
    #else
    Auth.auth().setAPNSToken(deviceToken, type: .prod)
    #endif
  }
  
  // Handle APNs token registration failure
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // Handle incoming notifications
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    completionHandler(.newData)
  }
  
  // Handle URL schemes (for reCAPTCHA redirect)
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    print("📱 Received URL: \(url.absoluteString)")
    
    if Auth.auth().canHandle(url) {
      print("✅ Firebase Auth handling URL")
      return true
    }
    
    print("⚠️ URL not handled by Firebase Auth, passing to super")
    return super.application(app, open: url, options: options)
  }
}