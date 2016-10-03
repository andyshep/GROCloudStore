//
//  VerifySubscriptionOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

final class VerifySubscriptionOperation: AsyncOperation {
    
    fileprivate let context: NSManagedObjectContext
    fileprivate let dataSource: CloudDataSource
    fileprivate let configuration: Configuration
    
    init(context: NSManagedObjectContext, dataSource: CloudDataSource, configuration: Configuration) {
        self.context = context
        self.dataSource = dataSource
        self.configuration = configuration
        super.init()
    }
    
    override func main() {
        var shouldCreateSubscription = true
        
        self.context.performAndWait {
            do {
                let request = NSFetchRequest<GROSubscription>(entityName: GROSubscription.entityName)
                let results = try self.context.fetch(request)
                if let _ = results.first {
                    shouldCreateSubscription = false
                }
            } catch {
                //
            }
        }
        
        if shouldCreateSubscription {
            dataSource.verifySubscriptions(completion: didFetch)
        } else {
            print("subscription verified, skipping creation")
            finish()
        }
    }
    
    fileprivate func createSubscriptions() {
        let configuration = dataSource.configuration
        let subscriptions = configuration.Subscriptions.Default
        dataSource.createSubscriptions(subscriptions: subscriptions, completion: didCreate)
    }
    
    fileprivate func didFetch(subscriptions: [CKSubscription]?, error: Error?) {
        
        guard error == nil else {
            attemptCloudKitRecoveryFrom(error: error! as NSError); return
        }
        
        // FIXME: should handle more than one subscription 
        
        var foundSubscription = false
        let defaultSubscription = self.configuration.Subscriptions.Default.first!
        if let subscriptions = subscriptions {
            if subscriptions.contains(defaultSubscription) {
                foundSubscription = true
            }
        }
        
        if foundSubscription {
            self.save(subscription: defaultSubscription, in: context)
        } else {
            createSubscriptions()
        }
    }
    
    fileprivate func didCreate(subscription: CKSubscription?, error: Error?) {
        if let error = error {
            print("error: \(error)")
        }
        
        if let subscription = subscription {
            print("successfully created subscription: \(subscription)")
        }
        
        finish()
    }
    
    fileprivate func save(subscription: CKSubscription, in context: NSManagedObjectContext) {
        context.perform {
            guard let savedSubscription = GROSubscription.newObject(in: context) as? GROSubscription else { return }
            
            savedSubscription.content = NSKeyedArchiver.archivedData(withRootObject: subscription)
            context.saveOrLogError()
        }
    }
}
