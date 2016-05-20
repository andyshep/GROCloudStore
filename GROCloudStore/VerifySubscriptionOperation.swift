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
    private let configuration: Configuration
    
    init(context: NSManagedObjectContext, dataSource: GROCloudDataSource, configuration: Configuration) {
        self.context = context
        self.dataSource = dataSource
        self.configuration = configuration
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
        let configuration = dataSource.configuration
        let subscriptions = configuration.Subscriptions.Default
        dataSource.createSubscriptions(subscriptions, completion: didCreateSubscription)
    }
    
    private func didFetchSubscriptions(subscriptions: [CKSubscription]?, error: NSError?) {
        if let _ = error {
            // TODO: handle partial error when no records exist?
            createSubscriptions()
        }
        else {
            
            var foundSubscriptions: [CKSubscription: Bool] = [:]
            for subscription in self.configuration.Subscriptions.Default {
                foundSubscriptions[subscription] = false
            }
            
            if let subscriptions = subscriptions {
                for subscription in subscriptions {
                    if let _ = foundSubscriptions[subscription] {
                        foundSubscriptions[subscription] = true
                    }
                }
            }
            
            for obj in foundSubscriptions {
                let subscription = obj.0
                let found = obj.1
                
                if found {
                    self.saveSubscription(subscription, context: self.context)
                }
                else {
                    createSubscriptions()
                }
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