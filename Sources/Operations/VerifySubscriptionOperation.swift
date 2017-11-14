//
//  VerifySubscriptionOperation.swift
//  GROCloudStore
//
//  Created by Andrew Shepard on 2/17/16.
//  Copyright © 2016 Andrew Shepard. All rights reserved.
//

import CoreData
import CloudKit

final internal class VerifySubscriptionOperation: AsyncOperation {
    
    private let context: NSManagedObjectContext
    private let dataSource: CloudDataSource
    private let configuration: Configuration
    
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
    
    private func createSubscriptions() {
        let configuration = dataSource.configuration
        let subscriptions = configuration.subscriptions.all
        dataSource.createSubscriptions(subscriptions: subscriptions, completion: didCreate)
    }
    
    private func didFetch(subscriptions: [CKSubscription]?, error: Error?) {
        
        guard error == nil else {
            attemptCloudKitRecoveryFrom(error: error! as NSError); return
        }
        
        // FIXME: should handle more than one subscription 
        
        var foundSubscription = false
        let defaultSubscription = self.configuration.subscriptions.all.first!
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
    
    private func didCreate(subscription: CKSubscription?, error: Error?) {
        if let error = error {
            print("error: \(error)")
        }
        
        if let subscription = subscription {
            print("successfully created subscription: \(subscription)")
        }
        
        finish()
    }
    
    private func save(subscription: CKSubscription, in context: NSManagedObjectContext) {
        context.perform {
            guard let savedSubscription = GROSubscription.newObject(in: context) as? GROSubscription else { return }
            
            savedSubscription.content = NSKeyedArchiver.archivedData(withRootObject: subscription)
            context.saveOrLogError()
        }
    }
}
