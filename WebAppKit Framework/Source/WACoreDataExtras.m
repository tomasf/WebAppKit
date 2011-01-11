//
//  WSCoreDataExtras.m
//  WebTest
//
//  Created by Tomas Franzén on 2010-12-15.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WACoreDataExtras.h"


@implementation NSManagedObjectContext (WAExtras)

+ (id)managedObjectContextWithModels:(NSArray*)momURLs store:(NSURL*)storeURL type:(NSString*)storeType {
	NSMutableArray *models = [NSMutableArray array];
	for(NSURL *momURL in momURLs) {
		if(![[NSFileManager defaultManager] fileExistsAtPath:[momURL path]]) {
			NSLog(@"MOM file does not exist: %@", momURL);
			return nil;
		}
		
		NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:momURL] autorelease];
		if(!model) {
			NSLog(@"Failed to create MOM from file: %@", momURL);
			return nil;
		}

		[models addObject:model];
	}
	
	NSManagedObjectModel *model = [NSManagedObjectModel modelByMergingModels:models];
	NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
	NSError *error = nil;
	
	if(![coordinator addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:nil error:&error]) {
		NSLog(@"Store path: %@", [storeURL path]);
		[NSException raise:NSInvalidArgumentException format:@"%@ failed to load persistent store: %@", self, error];		
	}
	
	NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
	[moc setPersistentStoreCoordinator:coordinator];	
	return moc;
}


+ (id)managedObjectContextFromModelNamed:(NSString*)modelName storeName:(NSString*)storeName type:(NSString*)storeType {
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:modelName withExtension:@"mom"];
	NSString *appSupportDirectory = WAApplicationSupportDirectory();
	
	NSURL *storeURL = [NSURL fileURLWithPath:[appSupportDirectory stringByAppendingPathComponent:storeName]];
	return [self managedObjectContextWithModels:[NSArray arrayWithObject:modelURL] store:storeURL type:storeType];
}


- (void)deleteObjectsUsingFetchRequest:(NSFetchRequest*)request {
	NSArray *matches = [self executeFetchRequest:request error:NULL];
	for(NSManagedObject *match in matches)
		[self deleteObject:match];
}


- (id)firstMatchForFetchRequest:(NSFetchRequest*)request {
	[request setFetchLimit:1];
	NSError *error;
	NSArray *matches = [self executeFetchRequest:request error:&error];
	return [matches lastObject];
}


@end




@implementation NSManagedObject (WAExtras)


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