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
    
    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("could not register for notfications: \(error)")
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        guard
            let notificationDictionary = userInfo as? [String: NSObject],
            let cloudNotification = CKNotification(fromRemoteNotificationDictionary: notificationDictionary),
            let subscriptionID = cloudNotification.subscriptionID,
            subscriptionID == Subscription.Name.Todo.rawValue
        else { return }
        
        guard let windowController = NSApp.windows.first?.windowController as? WindowController else {
            print("couldn't find controller to handle cloud change notification")
            return
        }
        
        windowController.arrayController.fetch(nil)
    }
}

