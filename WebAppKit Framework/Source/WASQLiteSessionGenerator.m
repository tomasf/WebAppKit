//
//  WASQLiteSessionManager.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASQLiteSessionGenerator.h"
#import "FMDatabase.h"
#import "WASQLiteSession.h"

@implementation WASQLiteSessionGenerator


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
	return [[WASQLiteSession alloc] initWithDatabase:database name:name request:request response:response];
}


@end