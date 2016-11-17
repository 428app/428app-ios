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
            handleRemote(userInfo: userInfo)
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
    open func handleRemote(userInfo: [AnyHashable: Any], isForeground: Bool = false) {
        /**
         type: topic|connection|settings,
         image: "",
         uid: "",
         tid: "",
         aps: {
            alert = {
                body = ""; title = ""
            },
            badge = 1;
            sound = default;
         }
         **/
        guard let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? [String: String], let badge = aps["badge"] as? Int else {
            return
        }
        
        guard let title = alert["title"], let body = alert["body"], let type = userInfo["type"] as? String, let uid = userInfo["uid"] as? String, let tid = userInfo["tid"] as? String, let imageUrlString = userInfo["image"] as? String else {
            return
        }
        
        if isForeground {
            // Download image, then show popup after complete
            _ = downloadImage(imageUrlString: imageUrlString, completed: { (image) in
                self.showPopup(title: title, subtitle: body, image: image, uid: uid, tid: tid, type: type)
            })
        } else {
            // In background, set the right page to transition to based on type, and uid/tid
        }
    }
    
    // Get visible view controller to show the remote notification popup on
    fileprivate func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        
        var rootVC = rootViewController
        if rootVC == nil {
            rootVC = UIApplication.shared.keyWindow?.rootViewController
        }
        
        if rootVC?.presentedViewController == nil {
            return rootVC
        }
        
        if let presented = rootVC?.presentedViewController {
            if presented.isKind(of: UINavigationController.self) {
                let navigationController = presented as! UINavigationController
                return navigationController.viewControllers.last!
            }
            
            if presented.isKind(of: UITabBarController.self) {
                let tabBarController = presented as! UITabBarController
                return tabBarController.selectedViewController!
            }
            
            return getVisibleViewController(presented)
        }
        return nil
    }
    
    // Used to show popup in the right view controller
    fileprivate func showPopup(title: String, subtitle: String, image: UIImage?, uid: String, tid: String, type: String) {
        // Note that image can be nil
        let announcement = Announcement(title: title, subtitle: subtitle, image: image, duration: 2.0, action: nil)
        guard let vc = self.getVisibleViewController(self.window?.rootViewController), let nvc = vc as? CustomNavigationController else { // Check for custom navigation controller is crucial, if not popup will show up even on LoginScreen
            return
        }
        
        // Do not show popup in the follow screens:
        if let _ = nvc.visibleViewController as? ProfileController {
            return
        }
        if let _ = nvc.visibleViewController as? PictureModalController {
            return
        }
        if let _ = nvc.visibleViewController as? IntroController {
            return
        }
        if let _ = nvc.visibleViewController as? DiscussModalController {
            return
        }
        
        if let chatVC = nvc.visibleViewController as? ChatController {
            // Only show popup if the chatVC uid is different from the uid in payload
            if chatVC.connection.uid != uid {
                show(shout: announcement, to: vc, completion: {
                    // This callback is reached when user taps, so we transition to the right page based on type, and uid/tid
                    self.transitionToRightScreenBasedOnType(type: type, tid: tid, uid: uid)
                })
            }
        } else {
            // Show for all other screens
            show(shout: announcement, to: vc, completion: {
                self.transitionToRightScreenBasedOnType(type: type, tid: tid, uid: uid)
            })
        }

    }
    
    fileprivate func transitionToRightScreenBasedOnType(type: String, tid: String, uid: String) {
        
        guard let tabBarController = self.window?.rootViewController?.presentedViewController as? CustomTabBarController, let vcs = tabBarController.viewControllers else {
            return
        }
        
        if type == "connection" {
            // Open the correct connection that matches uid
            guard let connectionsNVC = vcs[0] as? CustomNavigationController, let connectionsVC = connectionsNVC.viewControllers.first as? ConnectionsController else {
                return
            }
            
            if connectionsNVC.viewControllers.count > 1 {
                // Currently in a chat screen or profile screen, etc., need to dismiss back to ConnectionsController before pushing ChatController
                connectionsNVC.popToRootViewController(animated: false)
            }
            
            // Look for the correct connection in latest messages
            let correctMessage = connectionsVC.latestMessages.filter() {$0.connection.uid == uid}
            if correctMessage.count != 1 {
                log.error("[Error] Uid could not be found in connections / too many of the same uid")
                return
            }
            let chatVC: ChatController = ChatController()
            chatVC.connection = correctMessage[0].connection
            connectionsNVC.pushViewController(chatVC, animated: false)
            tabBarController.selectedIndex = 0

        } else if type == "topic" {
            // Open the correct topic that matches tid
            guard let topicsNVC = vcs[1] as? CustomNavigationController, let topicsVC = topicsNVC.viewControllers.first as? TopicsController else {
                return
            }
            if topicsNVC.viewControllers.count > 1 {
                // Currently in a discuss screen or profile screen, etc., need to dismiss back to TopicsController before pushing DiscussController
                topicsNVC.popToRootViewController(animated: false)
            }
            // Look for the correct topic in all topics
            let correctTopic = topicsVC.topics.filter() {$0.tid == tid}
            if correctTopic.count != 1 {
                log.error("[Error] Tid could not be found in topics / too many of the same tid")
                return
            }
            let discussVC: DiscussController = DiscussController()
            discussVC.topic = correctTopic[0]
            topicsNVC.pushViewController(discussVC, animated: false)
            tabBarController.selectedIndex = 1
        }
    }
    
    // Received in foreground (iOS 9)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleRemote(userInfo: userInfo, isForeground: true)
    }
    
    // Launched from background (iOS 9)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        handleRemote(userInfo: userInfo)
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
        handleRemote(userInfo: userInfo, isForeground: true)
    }
    
    // Launched from background
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleRemote(userInfo: userInfo)
    }
}

extension AppDelegate : FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        // This is not used because we don't really send data messages
        log.info("Data message while app is in foreground: \(remoteMessage.appData)")
    }
}
