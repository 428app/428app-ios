//
//  AppDelegate.swift
//  ios-428-app
//
//  Created by Leonard Loo on 10/10/16.
//  Copyright © 2016 428. All rights reserved.
//

import UIKit
import UserNotifications

import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseMessaging
import FirebaseInstanceID
import Whisper


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.rootViewController = LoginController()
        UINavigationBar.appearance().isTranslucent = true
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
 
        handleRemoteNotificationsThatLaunchApp(launchOptions: launchOptions)
        setupRemoteNotifications(application: application)

        return FBSDKApplicationDelegate.sharedInstance()
            .application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // TODO:
        FIRMessaging.messaging().disconnect()
        UIApplication.shared.applicationIconBadgeNumber = 2
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        connectToFcm()
        // Might consider removing this if it is hitting the database too much
        DataService.ds.updateUserLastSeen{ (isSuccess) in
            if !isSuccess {
                log.error("[Error] Failed to set user last seen")
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // MARK: Remote notifications
    
    fileprivate func setupRemoteNotifications(application: UIApplication) {
        
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { (granted, error) in })
            
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            // iOS 9
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Add observer for callback to receive refreshed token
        // Note that this is only called when the token is new, so we don't have to keep updating our server's token for this user
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: .firInstanceIDTokenRefresh, object: nil)
    }
    
    fileprivate func handleRemoteNotificationsThatLaunchApp(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        // Grab push notifications from launch options if it is there
        if let userInfo = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: AnyObject] {
            transitionWithRemote(userInfo: userInfo)
        }
    }
    
    // This is called when app is in background
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
            // TODO: Store this token in server
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token
        connectToFcm()
    }
    
    fileprivate func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                log.error("[Error] Unable to connect with FCM. \(error)")
            } else {
                log.info("Connected to FCM.")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        log.error("[Error] Fail to register for remote notifications with error: \(error)")
        // Try again
        connectToFcm()
    }
    
    // Used to transition to the right page given valid userInfo dictionary from remote notification payload
    open func transitionWithRemote(userInfo: [AnyHashable: Any], isForeground: Bool = false) {
        /**
         aps: {
            alert = {
                body = ""; title = "";
            },
            badge = 1;
            sound = default;
         }
         **/
        if let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? [String: String], let badge = aps["badge"] as? Int {
            // TODO: If is foreground, show a display banner
            // Post a notif to all view controllers, which will have that observer
            
            log.info("\(alert)")
        }
        
        
    }
    
    // Received in foreground
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        transitionWithRemote(userInfo: userInfo, isForeground: true)
    }
    
    // Launched from background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        transitionWithRemote(userInfo: userInfo)
        
//        Message(title: "Enter your message here.", backgroundColor: UIColor.redColor())
    }

}


extension UIViewController {
    
    func showRemoteNotificationPopup() {
        
    }
    
}

// Handling of iOS 10 
// These are launched instead of the the iOS 9 default remote notifications functions when iOS 10

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Received in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        transitionWithRemote(userInfo: userInfo, isForeground: true)
    }
    
    // Launched from background
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        log.info("In didreceive")
        transitionWithRemote(userInfo: userInfo)
    }
}

extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        // This is not used because we don't really send data messages
        log.info("Data message while app is in foreground: \(remoteMessage.appData)")
    }
}
