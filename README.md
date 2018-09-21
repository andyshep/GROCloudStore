![logo](http://i.imgur.com/QdBaUDY.png)

# GROCloudStore

![Swift 4.0](https://img.shields.io/badge/swift-4.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-ios%20%7C%20macos-lightgrey.svg)

GROCloudStore provides an `NSIncrementalStore` subclass that is backed by CloudKit, allowing data to be loaded from the cloud into your Core Data model. GROCloudStore works by augmenting your existing Core Data model with attributes so that records and entities can be tracked together. When saving to Core Data, `CKRecord` objects are created from managed objects and then saved to CloudKit.

GROCloudStore only supports the private CloudKit database. This is because GROCloudStore uses custom record zones which are not supported in the public database.

## Requirements

 * Xcode 10
 * Swift 4.2

## Configuration

Before using the store, it must be configured with some information about your specific CloudKit setup. At a high level, the store needs to know the CloudKit identifier and zone name and how to map between model objects and cloud records.

Below these configuration points are discussed in more detail.

1. Create a class conforming to the `Configuration` protocol. This protocol defines information about your CloudKit environment. Specifically, it defines the bucket and custom zone names and any record subscriptions.

```swift
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
```


2. Provide an instance of this configuration object when creating your Core Data stack. This should be done along with specifying `GROIncrementalStore.storeType` as the Persistent Store type.

```swift
let modelURL = Bundle.main.url(forResource: "Todos", withExtension: "momd")!
let model = NSManagedObjectModel(contentsOf: modelURL)!
let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

let options = [GROConfigurationKey: SampleConfiguration()]
let type = GROIncrementalStore.storeType
    
try! coordinator.addPersistentStore(ofType: storeType, configurationName: nil, at: url, options: options)

let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
managedObjectContext.persistentStoreCoordinator = coordinator

// continue to use the managed object context
```
		
3. Add an `NSData` attribute called `encodedSystemFields` on your Core Data model objects. This field is used to store the result of calling [encodeSystemFieldsWithCoder](https://developer.apple.com/library/ios/documentation/CloudKit/Reference/CKRecord_class/#//apple_ref/occ/instm/CKRecord/encodeSystemFieldsWithCoder:) on your `CKRecord` objects.

```swift
class MyModelObject: NSManagedObject {
	@NSManaged var name: String?
	@NSManaged var date: Date?

	@NSManaged var encodedSystemFields: Data?
}
```

4. Conform to the `ManagedObjectTransformable` and `CloudKitTransformable` protocols on your model objects. These protocols allow you to define how objects are translated between `CKRecords` and `NSManagedObjects`.
	
```swift
extension MyModelObject: ManagedObjectTransformable {

    func transform(using object: NSManagedObject) {
        guard let item = object.value(forKeyPath: "item") as? String else { return }
        self.item = item
        
        guard let created = object.value(forKeyPath: "created") as? Date else { return }
        self.created = created
        
        guard let data = object.value(forKeyPath: "encodedSystemFields") as? Data else { fatalError() }
        self.encodedSystemFields = data
    }
}

extension MyModelObject: CloudKitTransformable {

    func transform(record record: CKRecord) {
        guard let name = record["name"] as? String else { return }
        self.name = name
        
        guard let date = record["date"] as? NSDate else { return }
        self.date = date
        
        self.record = record
    }
    
    func transform() -> CKRecord {
        let record = self.record
        record["name"] = self.name
        record["date"] = self.date
        
        return record
    }
}
```

## Example

There is an example Todos app that shows how to integrate with GROCloudStore. The app displays a task list of items to do, using a single Core Data entity.

Before the example can be used, you'll need to do the following.

1.  Be logged into iCloud on your Mac or through the iOS simulator
2.  Change the bundle identifier and iCloud bucket to something unique
3.  Generate an entitlements file using your Apple developer account.

# Credits

GROCloudStore is inspired by the design of [AFIncrementalStore](https://github.com/AFNetworking/AFIncrementalStore/tree/development), especially the use of multiple persistent stores and augmenting the managed object model. Additionally, the [Advanced Operations](https://developer.apple.com/videos/play/wwdc2015/226/) presentation from WWDC 2015 and the sample code provided formed the basis of the CloudKit syncing layer.

## License

GROCloudStore is released under the MIT license. See LICENSE for details.