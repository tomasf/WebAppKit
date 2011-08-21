#import "TFCoreDataExtras.h"


static NSString *TFApplicationName() {
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *name = [[bundle infoDictionary] objectForKey:@"CFBundleName"];
	if(!name) name = [[bundle executablePath] lastPathComponent];
	return name;
}

static NSString *TFApplicationSupportDirectory() {	
	NSString *appSupportPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
	appSupportPath = [appSupportPath stringByAppendingPathComponent:TFApplicationName()];
#endif
	[[NSFileManager defaultManager] createDirectoryAtPath:appSupportPath withIntermediateDirectories:YES attributes:nil error:nil];
	return appSupportPath;
}



@implementation NSManagedObjectContext (TFCoreDataExtras)


+ (id)managedObjectContextWithModel:(NSManagedObjectModel*)model store:(NSURL*)storeURL type:(NSString*)storeType {
	NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
	NSError *error = nil;
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 nil];
	
	if(![coordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:options error:&error]) {
		NSLog(@"Store: %@", [storeURL path]);
		NSLog(@"Model: %@", model);
		[NSException raise:NSInvalidArgumentException format:@"Failed to load persistent store: %@", error];		
	}
	
	NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
	[moc setPersistentStoreCoordinator:coordinator];	
	return moc;
}


+ (id)managedObjectContextFromModelNamed:(NSString*)modelName inBundle:(NSBundle*)bundle storeName:(NSString*)storeName type:(NSString*)storeType {
	NSURL *modelURL = [bundle URLForResource:modelName withExtension:@"momd"];
	
	if(!modelURL) {
		modelURL = [bundle URLForResource:modelName withExtension:@"mom"];
		if(!modelURL)
			[NSException raise:NSInvalidArgumentException format:@"Model file '%@' (.mom/.momd) not found!", modelName];
	}
	
	NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
	if(!model) {
		[NSException raise:NSInvalidArgumentException format:@"Failed to create MOM from file: %@", modelURL];
		return nil;
	}
		
	NSString *appSupportDirectory = TFApplicationSupportDirectory();
	NSURL *storeURL = [NSURL fileURLWithPath:[appSupportDirectory stringByAppendingPathComponent:storeName]];
	return [self managedObjectContextWithModel:model store:storeURL type:storeType];
}


+ (id)managedObjectContextFromModelNamed:(NSString*)modelName storeName:(NSString*)storeName type:(NSString*)storeType {
	return [self managedObjectContextFromModelNamed:modelName inBundle:[NSBundle mainBundle] storeName:storeName type:storeType];	
}


+ (id)managedObjectContextWithStoreName:(NSString*)storeName type:(NSString*)storeType {
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
	if(!model)
		[NSException raise:NSInvalidArgumentException format:@"mergedModelFromBundles: returned nil"];
	
	NSString *appSupportDirectory = TFApplicationSupportDirectory();
	NSURL *storeURL = [NSURL fileURLWithPath:[appSupportDirectory stringByAppendingPathComponent:storeName]];
	return [self managedObjectContextWithModel:model store:storeURL type:storeType];	
}


- (id)firstMatchForFetchRequest:(NSFetchRequest*)request {
	[request setFetchLimit:1];
	NSError *error;
	NSArray *matches = [self executeFetchRequest:request error:&error];
	return [matches lastObject];
}


- (void)saveOrRaise {
	NSError *error = nil;
	if(![self save:&error])
		[NSException raise:NSGenericException format:@"Failed to save MOC: %@", error];
}


@end




@implementation NSManagedObject (TFCoreDataExtras)


- (id)initInsertingIntoManagedObjectContext:(NSManagedObjectContext*)moc {
	NSEntityDescription *entity = [[self class] entityInManagedObjectContext:moc];
	return [self initWithEntity:entity insertIntoManagedObjectContext:moc];
}


+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSString *className = NSStringFromClass(self);
	NSManagedObjectModel *model = [[moc persistentStoreCoordinator] managedObjectModel];
	
	for(NSEntityDescription *entity in [model entities])
		if([[entity managedObjectClassName] isEqual:className])
			return entity;
	
	return nil;
}


+ (NSArray*)objectsMatchingFetchRequest:(NSFetchRequest*)req managedObjectContext:(NSManagedObjectContext*)moc {
	NSEntityDescription *entity = [self entityInManagedObjectContext:moc];
	NSAssert2(entity, @"Failed to find entity for class %@ in MOC %@", self, moc);
	[req setEntity:entity];
	
	NSError *error;
	return [moc executeFetchRequest:req error:&error];
}


+ (NSArray*)objectsInManagedObjectContext:(NSManagedObjectContext*)moc sorting:(NSArray*)sortDescriptors matchingPredicateFormat:(NSString*)format, ... {
	NSPredicate *predicate = nil;
	if(format) {
		va_list list;
		va_start(list, format);
		predicate = [NSPredicate predicateWithFormat:format arguments:list];
		va_end(list);
	}
	
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];
	if(predicate) [req setPredicate:predicate];
	if(sortDescriptors) [req setSortDescriptors:sortDescriptors];
	
	return [self objectsMatchingFetchRequest:req managedObjectContext:moc];		
}


+ (NSArray*)objectsInManagedObjectContext:(NSManagedObjectContext*)moc sortedBy:(NSString*)keyPath ascending:(BOOL)asc matchingPredicateFormat:(NSString*)format, ... {
	NSPredicate *predicate = nil;
	if(format) {
		va_list list;
		va_start(list, format);
		predicate = [NSPredicate predicateWithFormat:format arguments:list];
		va_end(list);
	}
	
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];
	if(predicate) [req setPredicate:predicate];
	if(keyPath) [req setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:keyPath ascending:asc]]];
	
	return [self objectsMatchingFetchRequest:req managedObjectContext:moc];		
}


+ (NSArray*)objectsInManagedObjectContext:(NSManagedObjectContext*)moc matchingPredicateFormat:(NSString*)format, ... {
	va_list list;
	va_start(list, format);
	NSPredicate *predicate = [NSPredicate predicateWithFormat:format arguments:list];
	va_end(list);
	
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];
	[req setPredicate:predicate];
	
	return [self objectsMatchingFetchRequest:req managedObjectContext:moc];		
}


+ (NSArray*)allObjectsInManagedObjectContext:(NSManagedObjectContext*)moc {
	NSFetchRequest *req = [[[NSFetchRequest alloc] init] autorelease];	
	return [self objectsMatchingFetchRequest:req managedObjectContext:moc];		
}


@end