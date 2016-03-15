//
//  VerifySubscriptionOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

class VerifySubscriptionOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    private let dataSource: GROCloudDataSource
    
    init(context: NSManagedObjectContext, dataSource: GROCloudDataSource) {
        self.context = context
        self.dataSource = dataSource
        super.init()
    }
    
    override func main() {
        var shouldCreateSubscription = true
        
        self.context.performBlockAndWait {
            do {
                let request = NSFetchRequest(entityName: GROSubscription.entityName)
                let results = try self.context.executeFetchRequest(request)
                if let _ = results.first as? GROSubscription {
                    shouldCreateSubscription = false
                }
            }
            catch {
                //
            }
        }
        
        if shouldCreateSubscription {
            dataSource.verifySubscriptions(didFetchSubscriptions)
        }
        else {
            print("subscription verified, skipping creation")
            finish()
        }
    }
    
    private func createSubscriptions() {
        let subscriptions = Subscription.Default
        dataSource.createSubscriptions(subscriptions, completion: didCreateSubscription)
    }
    
    private func didFetchSubscriptions(subscriptions: [CKSubscription]?, error: NSError?) {
        if let _ = error {
            // TODO: handle partial error when no records exist?
            createSubscriptions()
        }
        else {
            
            var foundSubscription: CKSubscription? = nil
            if let subscriptions = subscriptions {
                for subscription in subscriptions {
                    if subscription.subscriptionID == Subscription.PlantChanges {
                        foundSubscription = subscription
                        break
                    }
                }
            }
            
            if let _ = foundSubscription {
                self.saveSubscription(foundSubscription!, context: self.context)
                finish()
            }
            else {
                createSubscriptions()
            }
        }
    }
    
    private func didCreateSubscription(subscription: CKSubscription?, error: NSError?) {
        if let error = error {
            print("error: \(error)")
        }
        
        if let subscription = subscription {
            print("successfully created subscription: \(subscription)")
        }
        
        finish()
    }
    
    private func saveSubscription(subscription: CKSubscription, context: NSManagedObjectContext) {
        context.performBlock {
            guard let savedSubscription = GROSubscription.newObjectInContext(context) as? GROSubscription else { return }
            
            savedSubscription.content = NSKeyedArchiver.archivedDataWithRootObject(subscription)
            context.saveOrLogError()
        }
    }
}