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
import Social

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.white
        window?.makeKeyAndVisible()
        window?.rootViewController = LoginController()
        UINavigationBar.appearance().isOpaque = true
        FIRApp.configure()
        FIRDatabase.database().persistenceEnabled = true
        
        setPromptForAnswerVote(hasPrompt: true) // For the future when answers from playgroup shows up, show answer prompt once
        
        // Reupload previous photo that might not have been uploaded due to nLogetwork issues or user quitting the app after changing profile photo
        reuploadPhoto()
 
        // Note that if a remote notification launches the app, we will NOT support directing it to the right page because the data has likely not been loaded and it can very tricky to wait for data to load before pushing the right page (even worse under bad network conditions!)
        setupRemoteNotifications(application: application)

        return FBSDKApplicationDelegate.sharedInstance()
            .application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        DataService.ds.getPushCount { (pushCount) in
            UIApplication.shared.applicationIconBadgeNumber = pushCount
        }
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FIRMessaging.messaging().disconnect()   
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
                log.warning("Unable to set user last seen")
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
    
    // MARK: Reupload profile photo if user previously closed app without finishing upload
    
    fileprivate func reuploadPhoto() {
        myProfilePhoto = getPhotoToUpload()
        if myProfilePhoto != nil { // There is a photo that is previously uploaded but user quit the app
            // Retry upload of image
            if let imageData = UIImageJPEGRepresentation(myProfilePhoto!, 1.0) {
                StorageService.ss.uploadOwnPic(data: imageData, completed: { (isSuccess) in
                    if !isSuccess {
                        log.error("[Error] Unable to upload profile pic to storage")
                    } else {
                        // Upload success, delete cached profile photo
                        cachePhotoToUpload(data: nil)
                    }
                })
            }
        }
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
        /**
         type: "playgroup" or "inbox" or "alert",
         image: "",
         uid: "",
         pid: "",
         aps: {
            alert = {
                body = ""; title = ""
            },
            badge = 1;
            sound = default;
         }
         **/
        guard let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? [String: String], let _ = aps["badge"] as? Int else {
            return
        }
        
        guard let title = alert["title"], let body = alert["body"], let typeString = userInfo["type"] as? String, let type = TokenType(rawValue: typeString), let uid = userInfo["uid"] as? String, let pid = userInfo["pid"] as? String, let imageUrlString = userInfo["image"] as? String else {
            return
        }
        
        if isForeground {
            // First check if inApp setting is enabled or disabled
            if let canShowInApp = userInfo["inApp"] as? String {
                // False string is used here because we can't just case String to Bool from payload
                if canShowInApp == "false" {
                    return
                }
            }
            
            // Download image, then show popup after complete
            _ = downloadImage(imageUrlString: imageUrlString, completed: { (image) in
                self.showPopup(title: title, subtitle: body, image: image, uid: uid, pid: pid, type: type)
            })
        } else {
            // In background, set the right page to transition to based on type, and uid/tid
            self.transitionToRightScreenBasedOnType(type: type, uid: uid, pid: pid)
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
    fileprivate func showPopup(title: String, subtitle: String, image: UIImage?, uid: String, pid: String, type: TokenType) {
        // Note that image can be nil
        let announcement = Announcement(title: title, subtitle: subtitle, image: image, duration: 2.0, action: nil)
        guard let vc = self.getVisibleViewController(self.window?.rootViewController), let nvc = vc as? CustomNavigationController else { // Check for custom navigation controller is crucial, if not popup will show up even on LoginScreen
            return
        }
        
        // Do not show popup in these screens as they are modal views
        if let _ = nvc.visibleViewController as? ProfileController {
            return
        }
        if let _ = nvc.visibleViewController as? PictureModalController {
            return
        }
        if let _ = nvc.visibleViewController as? IntroController {
            return
        }
        if let _ = nvc.visibleViewController as? ModalQuestionController {
            return
        }
        
        // If popup is for playgroup chat that user is currently in, don't show popup
        if type == .PLAYGROUP {
            if let playgroupChatVC = nvc.visibleViewController as? ChatPlaygroupController {
                if playgroupChatVC.playgroup.pid == pid {
                    return
                }
            }
        }
        
        // If popup is for inbox chat that user is currently in, don't show popup
        if type == .INBOX {
            if let inboxChatVC = nvc.visibleViewController as? ChatInboxController {
                if inboxChatVC.inbox.uid == uid {
                    return
                }
            }
        }
        
        show(shout: announcement, to: vc, completion: {
            // This callback is reached when user taps, so we transition to the right page based on type, and uid/tid
            self.transitionToRightScreenBasedOnType(type: type, uid: uid, pid: pid)
        })
    }
    
    fileprivate func transitionToRightScreenBasedOnType(type: TokenType, uid: String, pid: String) {
        guard let rootVC = self.window?.rootViewController as? LoginController else {
            return
        }
        
        guard let tabBarController = rootVC.presentedViewController as? CustomTabBarController else {
            return
        }
        
        if type == .PLAYGROUP {
            self.findAndTransitionToPlaygroup(pid: pid, tabBarController: tabBarController)
        } else if type == .INBOX {
            self.findAndTransitionToInbox(uid: uid, tabBarController: tabBarController)
        } else if type == .ALERT {
            self.transitionToPlaygroupPageForAlert(tabBarController: tabBarController)
        }
    }
    
    // Open the correct private chat that matches uid
    fileprivate func findAndTransitionToInbox(uid: String, tabBarController: CustomTabBarController) {
        guard let vcs = tabBarController.viewControllers, let inboxNVC = vcs[2] as? CustomNavigationController, let inboxVC = inboxNVC.viewControllers.first as? InboxController else {
            return
        }
        
        if inboxNVC.viewControllers.count > 1 {
            // Currently in a chat screen or profile screen, etc., need to dismiss back to InboxController before pushing ChatInboxController
            inboxNVC.popToRootViewController(animated: false)
        }
        
        // Look for the correct private message in latest messages
        let correctMessage = inboxVC.latestMessages.filter() {$0.inbox.uid == uid}
        if correctMessage.count != 1 {
            tabBarController.selectedIndex = 2
            log.warning("Inbox not loaded yet")
            return
        }
        
        let chatVC: ChatInboxController = ChatInboxController()
        chatVC.inbox = correctMessage[0].inbox
        inboxNVC.viewControllers[0].navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        inboxNVC.pushViewController(chatVC, animated: false)
        tabBarController.selectedIndex = 2
    }
    
    // Open the correct playgroup that matches pid
    fileprivate func findAndTransitionToPlaygroup(pid: String, tabBarController: CustomTabBarController) {

        guard let vcs = tabBarController.viewControllers, let playgroupsNVC = vcs[1] as? CustomNavigationController, let playgroupsVC = playgroupsNVC.viewControllers.first as? PlaygroupsController else {
            return
        }
        if playgroupsNVC.viewControllers.count > 1 {
            // Currently in a screen on top of the PlaygroupsController stack, i.e. in a Chat, etc. - need to pop back to the PlaygroupsController
            playgroupsNVC.popToRootViewController(animated: false)
        }
        
        // Look for the correct playgroup in all playgroups
        
        // Note: Because PlaygroupVC is not loaded by default, the playgroups array might still be empty until the user clicks on the Playgroups tab. In that case, we just change the tab index instead of going into the individual playgroup.
        let correctPlaygroup = playgroupsVC.playgroups.filter() {$0.pid == pid}
        if correctPlaygroup.count != 1 {
            tabBarController.selectedIndex = 1
            log.warning("Playgroups not loaded yet")
            return
        }
        let classChatVC: ChatPlaygroupController = ChatPlaygroupController()
        classChatVC.playgroup = correctPlaygroup[0]
        playgroupsNVC.viewControllers[0].navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        playgroupsNVC.pushViewController(classChatVC, animated: false)
        tabBarController.selectedIndex = 1
    }
    
    // Transition to playgroup tab upon receiving any alert
    fileprivate func transitionToPlaygroupPageForAlert(tabBarController: CustomTabBarController) {
        guard let vcs = tabBarController.viewControllers, let playgroupsNVC = vcs[1] as? CustomNavigationController, let _ = playgroupsNVC.viewControllers.first as? PlaygroupsController else {
            return
        }
        if playgroupsNVC.viewControllers.count > 1 {
            // Currently in a screen on top of the PlaygroupsController stack, i.e. in a Chat, etc. - need to pop back to the PlaygroupsController
            playgroupsNVC.popToRootViewController(animated: false)
        }
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.prod)
//        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
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
