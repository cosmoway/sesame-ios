//
//  ViewController.swift
//  sesame-ios
//
//  Created by 坂野健 on 2016/02/23.
//  Copyright © 2016年 坂野健. All rights reserved.
//


//
//  ViewController.swift
//  CoreLocation004
//


import UIKit
import Foundation
import AudioToolbox
import ReachabilitySwift
import CoreLocation
import CoreBluetooth


class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate {
    
    @IBOutlet weak var uuid: UILabel!
    @IBOutlet weak var minor1: UILabel!
    @IBOutlet weak var major1: UILabel!
    @IBOutlet weak var rssi1: UILabel!
    @IBOutlet weak var proximity1: UILabel!
    @IBOutlet weak var accuracy: UILabel!
    @IBOutlet weak var phoneUuid: UILabel!
    
    var sendFlag: Bool = false
    var myLocationManager:CLLocationManager!
    var myBeaconRegion:CLBeaconRegion!
    var beaconRegion = CLBeaconRegion()
    var myCentralManager: CBCentralManager!
    var bluetoothOn = true
    var wifiOn = true
    var errorFlag = false
    var userDefaults = NSUserDefaults(suiteName: "group.net.cosmoway.sesame")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("init")
        phoneUuid.text = UIDevice.currentDevice().identifierForVendor!.UUIDString
        print(UIDevice.currentDevice().identifierForVendor!.UUIDString)
        // CoreBluetoothを初期化および始動.
        myCentralManager = CBCentralManager(delegate: self, queue: nil, options: nil)

        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }
        
        reachability.whenReachable = { reachability in
            dispatch_async(dispatch_get_main_queue()) {
                if reachability.isReachableViaWiFi() {
                    print("Reachable via WiFi")
                    self.wifiOn = true
                } else {
                    print("Reachable via Cellular")
                    self.wifiOn = false
                }
            }
        }
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            dispatch_async(dispatch_get_main_queue()) {
                print("Not reachable")
                self.wifiOn = false
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
        //端末でiBeaconが使用できるかの判定できなければアラートをだす。
        if(CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion)) {
        
            // ロケーションマネージャの作成.
            myLocationManager = CLLocationManager()
        
            // デリゲートを自身に設定.
            myLocationManager.delegate = self
        
            // セキュリティ認証のステータスを取得
            let status = CLLocationManager.authorizationStatus()
        
            // 取得精度の設定.
            myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
            // 取得頻度の設定.(1mごとに位置情報取得)
            myLocationManager.distanceFilter = 1
        
            // まだ認証が得られていない場合は、認証ダイアログを表示
            if(status != CLAuthorizationStatus.AuthorizedAlways) {
                print("CLAuthorizedStatus: \(status)");
            
                // まだ承認が得られていない場合は、認証ダイアログを表示.
                myLocationManager.requestAlwaysAuthorization()
            }
        
        
            // BeaconのUUIDを設定.
            let uuid = NSUUID(UUIDString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
        
            // リージョンを作成.
            myBeaconRegion = CLBeaconRegion(proximityUUID: uuid!,identifier: "EstimoteRegion")
        
            // ディスプレイがOffでもイベントが通知されるように設定(trueにするとディスプレイがOnの時だけ反応).
            myBeaconRegion.notifyEntryStateOnDisplay = false
        
            // 入域通知の設定.
            myBeaconRegion.notifyOnEntry = true
        
            // 退域通知の設定.
            myBeaconRegion.notifyOnExit = true
        
            beaconRegion = myBeaconRegion
            
            myLocationManager.startMonitoringForRegion(myBeaconRegion)
        } else {
            let alert = UIAlertController(title: "確認", message: "お使いの端末ではiBeaconをご利用できません。", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "OK", style: .Default) { (action) -> Void in
                print("OK button tapped.")
            }
            
            alert.addAction(okAction)
            
            presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("state \(central.state)");
        switch (central.state) {
        case .PoweredOff:
            print("Bluetoothの電源がOff")
            bluetoothOn = false
        case .PoweredOn:
            print("Bluetoothの電源はOn")
            bluetoothOn = true
        case .Resetting:
            print("レスティング状態")
        case .Unauthorized:
            print("非認証状態")
        case .Unknown:
            print("不明")
        case .Unsupported:
            print("非対応")
        }
        var alertMessage: String?
        
        if (!bluetoothOn && !wifiOn) {
            alertMessage = "Wi-Fi/BluetoothをONにしてください。"
            print("wifiとbluetoothをオンにしてください。")
        } else if (!bluetoothOn) {
            alertMessage = "BluetoothをONにしてください。"
            print("bluetoothをオンにしてください。")
        } else if (!wifiOn) {
            alertMessage = "Wi-FiをONにしてください。"
            print("wifiをオンにしてください。")
        }
        
        if (alertMessage != nil) {
            let alertController = UIAlertController(title: "通知", message: alertMessage, preferredStyle: .Alert)
            
            let otherAction = UIAlertAction(title: "はい", style: .Default) {
                action in NSLog("はいボタンが押されました")
                self.myCentralManager = nil
            }
            
            // addActionした順に左から右にボタンが配置されます
            alertController.addAction(otherAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    /*
    (Delegate) 認証のステータスがかわったら呼び出される.
    */
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        print("didChangeAuthorizationStatus");
        
        // 認証のステータスをログで表示
        var statusStr = "";
        switch (status) {
        case .NotDetermined:
            statusStr = "NotDetermined"
        case .Restricted:
            statusStr = "Restricted"
        case .Denied:
            statusStr = "Denied"
        case .AuthorizedAlways:
            statusStr = "AuthorizedAlways"
        case .AuthorizedWhenInUse:
            statusStr = "AuthorizedWhenInUse"
        }
        print(" CLAuthorizationStatus: \(statusStr)")
        
        manager.startMonitoringForRegion(beaconRegion)
    }
    
    /*
    (Delegate): LocationManagerがモニタリングを開始したというイベントを受け取る.
    */
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        
        print("didStartMonitoringForRegion");
        
        // この時点でビーコンがすでにRegion内に入っている可能性があるので、その問い合わせを行う
        // (Delegate didDetermineStateが呼ばれる)
        manager.requestStateForRegion(region);
    }
    
    /*
    (Delegate): 現在リージョン内にいるかどうかの通知を受け取る.
    */
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        
        print("locationManager: didDetermineState \(state)")
        
        switch (state) {
            
        case .Inside: // リージョン内にいる
            print("CLRegionStateInside:");
            
            // すでに入っている場合は、そのままRangingをスタートさせる
            // (Delegate didRangeBeacons)
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
            break;
            
        case .Outside:
            print("CLRegionStateOutside:")
            // 外にいる、またはUknownの場合はdidEnterRegionが適切な範囲内に入った時に呼ばれるため処理なし。
            break;
            
        case .Unknown:
            print("CLRegionStateUnknown:")
            // 外にいる、またはUknownの場合はdidEnterRegionが適切な範囲内に入った時に呼ばれるため処理なし。
            
        }
    }
    
    /*
    (Delegate): ビーコンがリージョン内に入り、その中のビーコンをNSArrayで渡される.
    */
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        // 範囲内で検知されたビーコンはこのbeaconsにCLBeaconオブジェクトとして格納される
        // rangingが開始されると１秒毎に呼ばれるため、beaconがある場合のみ処理をするようにすること.
        // 通信用のConfigを生成.
        

        if(beacons.count > 0){
            
            // 発見したBeaconの数だけLoopをまわす
            for var i = 0; i < beacons.count; i++ {
                
                let beacon = beacons[i] 
                
                let beaconUUID = beacon.proximityUUID
                let minorID = beacon.minor
                let majorID = beacon.major
                let rssi = beacon.rssi
                let accuracy = beacon.accuracy
                
                print("UUID: \(beaconUUID.UUIDString)")
                print("minorID: \(minorID)")
                print("majorID: \(majorID)")
                print("RSSI: \(rssi)")
                print("accuracy: \(accuracy)")
                uuid.text = beaconUUID.UUIDString
                minor1.text = minorID.stringValue
                major1.text = majorID.stringValue
                rssi1.text = String(rssi)
                self.accuracy.text = String(accuracy)
                
                
                switch (beacon.proximity) {
                    
                case CLProximity.Unknown :
                    print("Proximity: Unknown")
                    proximity1.text = "Unknown"
                    userDefaults?.setObject("Unknown", forKey: "proximity")
                    userDefaults?.synchronize()
                    break
                    
                case CLProximity.Far:
                    print("Proximity: Far")
                    proximity1.text = "Far"
                    userDefaults?.setObject("Far", forKey: "proximity")
                    userDefaults?.synchronize()
                    if (!sendFlag) {
                        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                        //短いタイムアウト
                        config.timeoutIntervalForRequest = 20
                        //長居タイムアウト
                        config.timeoutIntervalForResource = 30
                        let session = NSURLSession(configuration: config)
                        // create the url-request
                        let urlString = "http://sesame.local:10080/?data=\((UIDevice.currentDevice().identifierForVendor!.UUIDString+"|"+majorID.stringValue+"|"+minorID.stringValue).sha256)"
                        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
                        
                        // set the method(HTTP-GET)
                        request.HTTPMethod = "GET"
                        
                        // use NSURLSessionDataTask
                        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
                            if (error == nil) {
                                let result = NSString(data: data!, encoding: NSUTF8StringEncoding)!
                                switch (result) {
                                case "200 OK":
                                    self.sendLocalNotificationWithMessage("開錠されました。")
                                    let soundIdRing:SystemSoundID = 1002  // new-mail.caf
                                    AudioServicesPlaySystemSound(soundIdRing)
                                    self.sendFlag = true
                                    break
                                case "400 Bad Request":
                                    self.errorFlag = true
                                    self.sendLocalNotificationWithMessage("予期せぬエラーが発生致しました。開発者に御問合せ下さい。")
                                    break
                                case "403 Forbidden":
                                    self.errorFlag = true
                                    self.sendLocalNotificationWithMessage("認証に失敗致しました。システム管理者に登録を御確認下さい。")
                                    break
                                default:
                                    self.sendLocalNotificationWithMessage(result as String)
                                    break
                                }
                                print(result)
                            } else {
                                self.errorFlag = true
                                self.sendLocalNotificationWithMessage("通信処理が正常に終了されませんでした。通信環境を御確認下さい。")
                                print(error)
                            }
                        })
                        task.resume()
                    }
                    break
                    
                case CLProximity.Near:
                    print("Proximity: Near")
                    proximity1.text = "Near"
                    userDefaults?.setObject("Near", forKey: "proximity")
                    userDefaults?.synchronize()
                    break
                    
                case CLProximity.Immediate:
                    print("Proximity: Immediate")
                    print("近いよ uuid:\(UIDevice.currentDevice().identifierForVendor!.UUIDString.sha256) major:\(majorID.stringValue.sha256) minor:\(minorID.stringValue.sha256)")
                    proximity1.text = "Immediate"
                    userDefaults?.setObject("Immediate", forKey: "proximity")
                    userDefaults?.synchronize()
                    break
                }
                
            }
        }
    }
    
    /*
    (Delegate) リージョン内に入ったというイベントを受け取る.
    */
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion");
        sendLocalNotificationWithMessage("領域に入りました")
        sendFlag = false
        var bgTask = UIBackgroundTaskIdentifier()
        bgTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler { () -> Void in
            UIApplication.sharedApplication().endBackgroundTask(bgTask)
        }
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
            // Rangingを始める
            manager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
        }
    }
    
    func beginBackgroundUpdateTask() -> UIBackgroundTaskIdentifier {
        return UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({})
    }
    
    func endBackgroundUpdateTask(taskID: UIBackgroundTaskIdentifier) {
        UIApplication.sharedApplication().endBackgroundTask(taskID)
    }
    
    /*
    (Delegate) リージョンから出たというイベントを受け取る.
    */
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("didExitRegion");
        sendLocalNotificationWithMessage("領域をでました")
        
        // Rangingを停止する
        manager.stopRangingBeaconsInRegion(region as! CLBeaconRegion)
    }
    
    //ローカル通知
    func sendLocalNotificationWithMessage(message: String!) {
        if (!sendFlag) {
            UIApplication.sharedApplication().cancelAllLocalNotifications();
            let notification:UILocalNotification = UILocalNotification()
            notification.alertBody = message
            if (self.errorFlag) {
                notification.category = "custom"
            }
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
    
}
extension String {
    var sha256: String! {
        return self.cStringUsingEncoding(NSUTF8StringEncoding).map { cstr in
            var chars = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
            CC_SHA256(
                cstr,
                CC_LONG(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)),
                &chars
            )
            return chars.map { String(format: "%02X", $0) }.reduce("", combine: +)
        }
    }
}
