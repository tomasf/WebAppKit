//
//  WASQLiteSessionManager.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionGenerator.h"
#import "FMDatabase.h"
#import "WASession.h"
#import "WARequest.h"

@interface WASession (Private)
- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n request:(WARequest*)req response:(WAResponse*)resp;
- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n token:(NSString*)tokenString;
@end


@interface WASessionGenerator ()
@property(copy) NSString *name;
@property(strong) FMDatabase *database;
@end



@implementation WASessionGenerator


+ (id)sessionGenerator {
	return [[self alloc] init];	
}


+ (id)sessionGeneratorWithName:(NSString*)name {
	return [[self alloc] initWithName:name];	
}


- (id)initWithName:(NSString*)name {
	NSAssert(name != nil, @"name cannot be nil");
	if(!(self = [super init])) return nil;
	self.name = name;
	
	NSString *filename = [name stringByAppendingPathExtension:@"db"];
	NSString *path = [WAApplicationSupportDirectory() stringByAppendingPathComponent:filename];
	
	self.database = [FMDatabase databaseWithPath:path];
	[self.database setLogsErrors:YES];
	
	if(![self.database open]) {
		[NSException raise:NSGenericException format:@"WASQLiteSessionGenerator: Failed to open session store SQLite database. Error %d (%@), path: %@", [self.database lastErrorCode], [self.database lastErrorMessage], path];
		return nil;
	}
	
	[self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS tokens (token)"];
	[self.database executeUpdate:@"CREATE TABLE IF NOT EXISTS `values` (token, `key`, value)"];
	[self.database executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS tokens_index ON tokens (token)"];
	[self.database executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS values_index ON `values` (token, `key`)"];
	
	return self;
}


- (id)init {
	return [self initWithName:@"Session"];
}


- (void)invalidate {
	[self.database close];
	self.database = nil;
}


- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response {
	NSAssert(request != nil && response != nil, @"sessionForRequest:response: needs non-nil request and response.");
	NSAssert(self.database != nil, @"can't create session from invalidated session generator");
	
	return [[WASession alloc] initWithDatabase:self.database name:self.name request:request response:response];
}


- (WASession*)sessionForToken:(NSString*)token {
	NSAssert(self.database != nil, @"can't create session from invalidated session generator");

	return [[WASession alloc] initWithDatabase:self.database name:self.name token:token];	
}


@end