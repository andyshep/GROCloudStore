//
//  AppDelegate.swift
//  Todos-OSX
//
//  Created by Andrew Shepard on 5/23/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import Cocoa
import CloudKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        NSApp.registerForRemoteNotifications(matching: [])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        NSApp.unregisterForRemoteNotifications()
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("registered for notifications: \(deviceToken)")
    }
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("could not register for notfications: \(error)")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : AnyObject]) {
        if let dictionary = userInfo as? [String: NSObject] {
            let cloudNotification = CKNotification(fromRemoteNotificationDictionary: dictionary)
            if cloudNotification.subscriptionID == Subscription.Todo {
                guard let windowController = NSApp.windows.first?.windowController as? WindowController else {
                    print("couldn't find controller to handle cloud change notification")
                    return
                }
                
                windowController.arrayController.fetch(nil)
            }
        }
    }
}

