#import <CoreData/CoreData.h>


@interface NSManagedObjectContext (TFCoreDataExtras)
+ (id)managedObjectContextWithModel:(NSManagedObjectModel*)model store:(NSURL*)storeURL type:(NSString*)storeType;
+ (id)managedObjectContextFromModelNamed:(NSString*)modelName storeName:(NSString*)storeName type:(NSString*)storeType;
+ (id)managedObjectContextWithStoreName:(NSString*)storeName type:(NSString*)storeType;

- (id)firstMatchForFetchRequest:(NSFetchRequest*)request;
- (void)saveOrRaise;
@end


@interface NSManagedObject (TFCoreDataExtras)
- (id)initInsertingIntoManagedObjectContext:(NSManagedObjectContext*)moc;

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc;
+ (NSArray*)objectsMatchingFetchRequest:(NSFetchRequest*)req managedObjectContext:(NSManagedObjectContext*)moc;
+ (NSArray*)objectsInManagedObjectContext:(NSManagedObjectContext*)moc sortedBy:(NSString*)keyPath ascending:(BOOL)asc matchingPredicateFormat:(NSString*)format, ...;
+ (NSArray*)objectsInManagedObjectContext:(NSManagedObjectContext*)moc sorting:(NSArray*)sortDescriptors matchingPredicateFormat:(NSString*)format, ...;
+ (NSArray*)objectsInManagedObjectContext:(NSManagedObjectContext*)moc matchingPredicateFormat:(NSString*)format, ...;
+ (NSArray*)allObjectsInManagedObjectContext:(NSManagedObjectContext*)moc;
@end