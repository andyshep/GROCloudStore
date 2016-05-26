# GROCloudStore

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

GROCloudStore provides an `NSIncrementalStore` subclass that is backed by CloudKit, allowing data to be loaded from the cloud into your Core Data model. GROCloudStore works by augmenting your existing Core Data model.

## Requirements

 * iOS 9.0+ / Mac OS X 10.11+
 * Xcode 7.3+

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

	$ brew update
	$ brew install carthage

To integrate GROCloudStore into your Xcode project using Carthage, specify it in your `Cartfile`:

	github "andyshep/GROCloudStore"

Run `carthage update` to build the framework and drag the built `Alamofire.framework` into your Xcode project.

### Cocoapods

TODO

### Manually

TODO

## Configuration

Before using the store, it must be configured with some information about your specific CloudKit setup. At a high level, the store needs to know the CloudKit identifier and zone name and how to map between model objects and cloud records.

Below these configuration points are discussed in more detail.

1. Create a class conforming to the `Configuration` protocol. This protocol defines information about your specific CloudKit environment.

		struct DefaultContainer: CloudContainerType {
		    var Identifier: String {
		        return "iCloud.org.example.domain.App"
		    }
		    
		    var CustomZoneName: String {
		        return "examplezonename"
		    }
		}
		
		struct Subscription: SubscriptionType {
		    var Default: [CKSubscription] {
		        return []
		    }
		}
		
		class SampleConfiguration: Configuration {
		    var Subscriptions: SubscriptionType {
		        return Subscription()
		    }
		    
		    var CloudContainer: CloudContainerType {
		        return DefaultContainer()
		    }
		}


2. Provide an instance of this configuration object when creating your Core Data stack. This should be done along with specifying `GROIncrementalStore.storeType` as the Persistent Store type.

		let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
		let model = NSManagedObjectModel(contentsOfURL: modelURL)!
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
	
		let options = [GROConfigurationKey: SampleConfiguration()]
		let type = GROIncrementalStore.storeType
            
		try! coordinator.addPersistentStoreWithType(type, configuration: nil, URL: nil, options: options)
		
3. Add an `NSData` attribute called `encodedSystemFields` on your Core Data model objects. This field is used to store the result of calling [encodeSystemFieldsWithCoder](https://developer.apple.com/library/ios/documentation/CloudKit/Reference/CKRecord_class/#//apple_ref/occ/instm/CKRecord/encodeSystemFieldsWithCoder:) on your `CKRecord` objects.


		class MyModelObject: NSManagedObject {
			@NSManaged var name: String?
			@NSManaged var date: NSDate?
    
			@NSManaged var encodedSystemFields: NSData?
		}

4. Conform to the `ManagedObjectTransformable` and `CloudKitTransformable` protocols on your model objects. These protocols allow you to define how objects are translated between `CKRecords` and `NSManagedObjects`.


## Example

There is an example Todos app that shows how to integrate with GROCloudStore. The app displays a task list of items to do, using a single Core Data entity. Before the example can be used, you'll need to have CloudKit enabled on your developer account. Change the app change id to something unique.

## License

GROCloudStore is released under the MIT license. See LICENSE for details.