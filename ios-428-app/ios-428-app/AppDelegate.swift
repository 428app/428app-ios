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
 
        // Note that if a remote notification launches the app, we will NOT support directing it to the right page because the data has likely not been loaded and it can very tricky to wait for data to load before pushing the right page (even worse under bad network conditions!)
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
        FIRMessaging.messaging().disconnect()
        // TODO: Set badge number correctly
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
        
        // Check for push token, if it is still in UserDefaults, update it
        DataService.ds.updateUserPushToken()
        
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
        // Note that this observer is never removed, because through the app's usage we want to monitor token refresh, and re-setup the token
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: .firInstanceIDTokenRefresh, object: nil)
    }
    
    // This is only called whenever the user gets a new token, and is triggered by the observer
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            log.info("User push token: \(refreshedToken)")
            savePushToken(token: refreshedToken)
            DataService.ds.updateUserPushToken()
        }
        // Connect to FCM since connection may have failed when attempted before having a token
        connectToFcm()
    }
    
    fileprivate func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                log.warning("Unable to connect with FCM. \(error)")
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
        log.info("\(userInfo)")
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
        
        guard let title = alert["title"], let body = alert["body"], let typeString = userInfo["type"] as? String, let type = TokenType(rawValue: typeString), let uid = userInfo["uid"] as? String, let tid = userInfo["tid"] as? String, let imageUrlString = userInfo["image"] as? String else {
            return
        }
        
        if isForeground {
            // Download image, then show popup after complete
            _ = downloadImage(imageUrlString: imageUrlString, completed: { (image) in
                self.showPopup(title: title, subtitle: body, image: image, uid: uid, tid: tid, type: type)
            })
        } else {
            // In background, set the right page to transition to based on type, and uid/tid
            self.transitionToRightScreenBasedOnType(type: type, uid: uid, tid: tid)
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
    fileprivate func showPopup(title: String, subtitle: String, image: UIImage?, uid: String, tid: String, type: TokenType) {
        // Note that image can be nil
        let announcement = Announcement(title: title, subtitle: subtitle, image: image, duration: 2.0, action: nil)
        guard let vc = self.getVisibleViewController(self.window?.rootViewController), let nvc = vc as? CustomNavigationController else { // Check for custom navigation controller is crucial, if not popup will show up even on LoginScreen
            return
        }
        
        // Do not show popup in these screens:
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
                    self.transitionToRightScreenBasedOnType(type: type, uid: uid, tid: tid)
                })
            }
        } else {
            // Show for all other screens
            show(shout: announcement, to: vc, completion: {
                self.transitionToRightScreenBasedOnType(type: type, uid: uid, tid: tid)
            })
        }
    }
    
    fileprivate func transitionToRightScreenBasedOnType(type: TokenType, uid: String, tid: String) {
        
        guard let rootVC = self.window?.rootViewController as? LoginController else {
            return
        }
        
        guard let tabBarController = rootVC.presentedViewController as? CustomTabBarController else {
            return
        }
        
        if type == .CONNECTION {
            self.findAndTransitionToConnection(uid: uid, tabBarController: tabBarController)
        } else if type == .TOPIC {
            self.findAndTransitionToTopic(tid: tid, tabBarController: tabBarController)
        }
    }
    
    // Open the correct connection that matches uid
    fileprivate func findAndTransitionToConnection(uid: String, tabBarController: CustomTabBarController) {
        
        guard let vcs = tabBarController.viewControllers, let connectionsNVC = vcs[0] as? CustomNavigationController, let connectionsVC = connectionsNVC.viewControllers.first as? ConnectionsController else {
            return
        }
        
        if connectionsNVC.viewControllers.count > 1 {
            // Currently in a chat screen or profile screen, etc., need to dismiss back to ConnectionsController before pushing ChatController
            connectionsNVC.popToRootViewController(animated: false)
        }
        
        // Look for the correct connection in latest messages
        let correctMessage = connectionsVC.latestMessages.filter() {$0.connection.uid == uid}
        if correctMessage.count != 1 {
            log.warning("Uid could not be found in connections / too many of the same uid")
            return
        }
        
        let chatVC: ChatController = ChatController()
        chatVC.connection = correctMessage[0].connection
        connectionsNVC.pushViewController(chatVC, animated: false)
        tabBarController.selectedIndex = 0
    }
    
    // Open the correct topic that matches tid
    fileprivate func findAndTransitionToTopic(tid: String, tabBarController: CustomTabBarController) {
        
        guard let vcs = tabBarController.viewControllers, let topicsNVC = vcs[1] as? CustomNavigationController, let topicsVC = topicsNVC.viewControllers.first as? TopicsController else {
            return
        }
        if topicsNVC.viewControllers.count > 1 {
            // Currently in a discuss screen or profile screen, etc., need to dismiss back to TopicsController before pushing DiscussController
            topicsNVC.popToRootViewController(animated: false)
        }
        // Look for the correct topic in all topics
        // Note: Because TopicVC is not loaded by default, the topics array might still be empty until the user clicks on the Topics tab. In that case, we just change the tab index instead of going into the individual topic.
        let correctTopic = topicsVC.topics.filter() {$0.tid == tid}
        if correctTopic.count != 1 {
            tabBarController.selectedIndex = 1
            log.warning("Tid could not be found in topics / too many of the same tid, OR page not loaded yet")
            return
        }
        let discussVC: DiscussController = DiscussController()
        discussVC.topic = correctTopic[0]
        topicsNVC.pushViewController(discussVC, animated: false)
        tabBarController.selectedIndex = 1
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
