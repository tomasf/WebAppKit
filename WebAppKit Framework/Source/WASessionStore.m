//
//  WSSessionStore.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-18.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WASessionStore.h"
#import "FMDatabase.h"
#import "WASession.h"

@interface WASession (Private)
- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n request:(WARequest*)req response:(WAResponse*)resp;
@end


@implementation WASessionStore

- (id)initWithName:(NSString*)n {
	self = [super init];
	name = [n copy];
	
	NSString *filename = [name stringByAppendingPathExtension:@"db"];
	NSString *path = [WAApplicationSupportDirectory() stringByAppendingPathComponent:filename];
	
	database = [FMDatabase databaseWithPath:path];
	[database setLogsErrors:YES];
	
	if(![database open])
		return nil;
	
	[database executeUpdate:@"CREATE TABLE IF NOT EXISTS tokens (token)"];
	[database executeUpdate:@"CREATE TABLE IF NOT EXISTS `values` (token, `key`, value)"];
	[database executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS tokens_index ON tokens (token)"];
	[database executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS values_index ON `values` (token, `key`)"];
	
	return self;
}

- (void)invalidate {
	[database close];
	database = nil;
}

- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response {
	return [[WASession alloc] initWithDatabase:database name:name request:request response:response];
}

@end
