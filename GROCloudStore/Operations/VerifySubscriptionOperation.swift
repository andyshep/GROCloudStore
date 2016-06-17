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
            }
            catch {
                //
            }
        }
        
        if shouldCreateSubscription {
            dataSource.verifySubscriptions(completion: didFetchSubscriptions)
        }
        else {
            print("subscription verified, skipping creation")
            finish()
        }
    }
    
    private func createSubscriptions() {
        let configuration = dataSource.configuration
        let subscriptions = configuration.Subscriptions.Default
        dataSource.createSubscriptions(subscriptions: subscriptions, completion: didCreateSubscription)
    }
    
    private func didFetchSubscriptions(_ subscriptions: [CKSubscription]?, error: NSError?) {
        
        guard error == nil else {
            attemptCloudKitRecoveryFrom(error: error!); return
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
            self.saveSubscription(defaultSubscription, context: self.context)
        }
        else {
            createSubscriptions()
        }
    }
    
    private func didCreateSubscription(_ subscription: CKSubscription?, error: NSError?) {
        if let error = error {
            print("error: \(error)")
        }
        
        if let subscription = subscription {
            print("successfully created subscription: \(subscription)")
        }
        
        finish()
    }
    
    private func saveSubscription(_ subscription: CKSubscription, context: NSManagedObjectContext) {
        context.perform {
            guard let savedSubscription = GROSubscription.newObject(in: context) as? GROSubscription else { return }
            
            savedSubscription.content = NSKeyedArchiver.archivedData(withRootObject: subscription)
            context.saveOrLogError()
        }
    }
}
