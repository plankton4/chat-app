//
//  ChatApp.swift
//  chatapp
//
//  Created by Dmitry Iv on 22.06.2022.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool
    {
        FirebaseApp.configure()
        
        /**
         * начинаем подключать пуши
         */

        Messaging.messaging().delegate = self
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        // [END register_for_notifications]
        
        /**
         * закончили подключать пуши
         */
        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    // вызывается при открытом приле (foreground)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions)
                                -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("PUSH Message ID: \(messageID)")
        }
        
        print("PUSH userNotificationCenter willPresent \(userInfo)")
        
        // Change this to your preferred presentation option
        // не показываем когда прил открыт
        //completionHandler([[.banner, .sound]])
    }
    
    // вызывается при свернутом приле (background)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("PUSH Message ID: \(messageID)")
        }
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        print("PUSH userNotificationCenter didReceive\(userInfo)")
        for (key, value) in userInfo {
            print("Key: \(key), value: \(value)")
        }
        
        AppGlobalState.pushUserInfo = userInfo
        NotificationCenter.default.post(
            name: .nameOpenFromPush,
            object: nil)
        
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("PUSH Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
        if let fcmToken = fcmToken {
            AppGlobalState.fcmToken = fcmToken
            
            if AppGlobalState.userId != 0 {
                WS.subscribeToPush(token: AppGlobalState.fcmToken)
                AppGlobalState.pushSubscribed = true
            }
        } else {
            print("Error in didReceiveRegistrationToken! Token in nil!")
        }
    }
}

@main
struct ChatApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var appGlobalState = AppGlobalState()
    @StateObject private var consts = Consts()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appGlobalState)
                .environmentObject(consts)
        }
    }
}
