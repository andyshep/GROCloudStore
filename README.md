# GROCloudStore

GROCloudStore provides an `NSIncrementalStore` subclass that is backed by CloudKit, allowing data to be loaded from the cloud into your Core Data model.

## Configuration

There are two configuration points that need to be addressed by your app before using GROCloudStore.

1. You must supply an object conforming to the `Configuration` protocol when creating your core data stack.

		let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
		let model = NSManagedObjectModel(contentsOfURL: modelURL)!
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
	
		let configuration = GROTestConfiguration()
		let options = [GROConfigurationKey: configuration]
		let type = GROIncrementalStore.storeType
            
		try! coordinator.addPersistentStoreWithType(type, configuration: nil, URL: nil, options: options)


2. Model objects needs to conform to `ManagedObjectTransformable` and `CloudKitTransformable`. These protocols allow you to define how your model objects are translated between `CKRecords` and `NSManagedObjects`.

## Example

There is an example Todos app that shows how to integrate with `GROCloudStore`. The app displays a task list of items to do, using a single Core Data entity. Before the example can be used, you'll need to have CloudKit enabled on your developer account. Change the app change id to something unique.

