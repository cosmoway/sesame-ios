//
//  TodayViewController.swift
//  ProximityExtension
//
//  Created by 坂野健 on 2016/03/07.
//  Copyright © 2016年 坂野健. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var labelText: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsDidChange:",
            name: NSUserDefaultsDidChangeNotification, object: nil)
        updateTextLabel()
        // Do any additional setup after loading the view from its nib.
    }
    @IBAction func updateButton(sender: AnyObject) {
        updateTextLabel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func userDefaultsDidChange(notification:NSNotification){
        updateTextLabel()
    }
    
    func updateTextLabel() {
        let defaults:NSUserDefaults = NSUserDefaults(suiteName: "group.net.cosmoway.sesame")!
        labelText.text = defaults.stringForKey("proximity")
        print(defaults.stringForKey("proximity"))
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        updateTextLabel()
        print("更新")
        completionHandler(NCUpdateResult.NewData)
    }
    
}
