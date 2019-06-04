//
//  AppDelegate.swift
//  RCTSwift
//
//  Created by DerekYang on 2018/2/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

import Firebase

//https://1384308.site123.me/
let appKey = "c01e5d79127d767cff5c90d4"
let channel = "Publish channel"
let isProduction = true

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  //  var bridge: RCTBridge!
  var shouldRotate: Bool = true
  //usage example in everywhere:   let appDelegate = UIApplication.shared.delegate as! AppDelegate
  //                               appDelegate.shouldRotate = false
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    FirebaseApp.configure()
    
    var jsCodeLocation: URL
    
    //    #if DEBUG
    jsCodeLocation = RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index", fallbackResource:nil)
    //    #else
//          jsCodeLocation = CodePush.bundleURL()
    //    #endif
    
    setupJPush(launchOptions)
    
    let rootView = RCTRootView(bundleURL: jsCodeLocation, moduleName: "example", initialProperties: nil, launchOptions: launchOptions)
    let rootViewController = UIViewController()
    rootViewController.view = rootView
    
    self.window = UIWindow(frame: UIScreen.main.bounds)
    self.window?.rootViewController = rootViewController
    self.window?.makeKeyAndVisible()
    
    
    
    return true
  }
  
  func setupJPush(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
  {
    if #available(iOS 10, *) {
      let entity = JPUSHRegisterEntity()
      entity.types = NSInteger(UNAuthorizationOptions.alert.rawValue) |
        NSInteger(UNAuthorizationOptions.sound.rawValue) |
        NSInteger(UNAuthorizationOptions.badge.rawValue)
      JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
      
    } else if #available(iOS 8, *) {
      // 可以自定义 categories
      JPUSHService.register(
        forRemoteNotificationTypes: UIUserNotificationType.badge.rawValue |
          UIUserNotificationType.sound.rawValue |
          UIUserNotificationType.alert.rawValue,
        categories: nil)
    } else {
      // ios 8 以前 categories 必须为nil
      JPUSHService.register(
        forRemoteNotificationTypes: UIRemoteNotificationType.badge.rawValue |
          UIRemoteNotificationType.sound.rawValue |
          UIRemoteNotificationType.alert.rawValue,
        categories: nil)
    }
    JPUSHService.setup(withOption: launchOptions, appKey: appKey, channel: channel, apsForProduction: isProduction)
  }
  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    application.applicationIconBadgeNumber = 0
    application.cancelAllLocalNotifications()
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
  {
    if shouldRotate {
      return .all
    } else {
      return .portrait
    }
  }
}

extension AppDelegate: JPUSHRegisterDelegate
{
  
  @available(iOS 10.0, *)
  func jpushNotificationCenter(_ center: UNUserNotificationCenter!, openSettingsFor notification: UNNotification?) {
    
  }
  
  
  
  @available(iOS 10.0, *)
  func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
    
    //    let userInfo = response.notification.request.content.userInfo
    //    let request = response.notification.request // 收到推送的请求
    //    let content = request.content // 收到推送的消息内容
    //
    //    let badge = content.badge // 推送消息的角标
    //    let body = content.body   // 推送消息体
    //    let sound = content.sound // 推送消息的声音
    //    let subtitle = content.subtitle // 推送消息的副标题
    //    let title = content.title // 推送消息的标题
    
  }
  
  @available(iOS 10.0, *)
  func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!,
                               withCompletionHandler completionHandler: ((Int) -> Void)!) {
    //    let userInfo = notification.request.content.userInfo
    //
    //    let request = notification.request // 收到推送的请求
    //    let content = request.content // 收到推送的消息内容
    //
    //    let badge = content.badge // 推送消息的角标
    //    let body = content.body   // 推送消息体
    //    let sound = content.sound // 推送消息的声音
    //    let subtitle = content.subtitle // 推送消息的副标题
    //    let title = content.title // 推送消息的标题
  }
  
  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("get the deviceToken  \(deviceToken)")
    NotificationCenter.default.post(name: Notification.Name(rawValue: "DidRegisterRemoteNotification"), object: deviceToken)
    JPUSHService.registerDeviceToken(deviceToken)
    
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("did fail to register for remote notification with error ", error)
    
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
    JPUSHService.handleRemoteNotification(userInfo)
    print("受到通知", userInfo)
    NotificationCenter.default.post(name: Notification.Name(rawValue: "AddNotificationCount"), object: nil)  //把  要addnotificationcount
  }
  
  func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
    //        JPUSHService.showLocalNotification(atFront: notification, identifierKey: nil)
  }
  
}
