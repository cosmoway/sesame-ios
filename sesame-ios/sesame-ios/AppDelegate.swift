//
//  AppDelegate.swift
//  sesame-ios
//
//  Created by 坂野健 on 2016/02/23.
//  Copyright © 2016年 坂野健. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // 通知許可をアラート表示にて
        //これがないとpermissionエラー
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Sound, .Alert, .Badge], categories: nil))
        // Notification Actionの作成
        let actionA = UIMutableUserNotificationAction()
        actionA.identifier = "actionA"
        actionA.title = "再送信"
        actionA.activationMode = UIUserNotificationActivationMode.Foreground
        actionA.authenticationRequired = false
        actionA.destructive = false
        
        // Category にまとめる
        let category = UIMutableUserNotificationCategory()
        // identifierは必ず設定する
        category.identifier = "custom"
        
        // 通知センター(上から引っ張るやつ)で表示される通知に使われる
        category.setActions([actionA], forContext: UIUserNotificationActionContext.Minimal)
        // アラートで表示される通知に使われる
        category.setActions([actionA], forContext: UIUserNotificationActionContext.Default)
        
        // 登録する
        let settings = UIUserNotificationSettings(
            forTypes: [.Sound, .Alert, .Badge],
            categories:NSSet(object: category) as? Set<UIUserNotificationCategory>)
        application.registerUserNotificationSettings(settings);
        return true
    }
    
    func application(application: UIApplication,
        handleActionWithIdentifier identifier:String?,
        forLocalNotification notification:UILocalNotification,
        completionHandler: (() -> Void)){
            
            NSNotificationCenter.defaultCenter().postNotificationName("actionPressed", object: nil)            
            completionHandler()
            
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

