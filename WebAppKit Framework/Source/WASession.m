//
//  WSSession.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-17.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WASession.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WACookie.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseAdditions.h"

static const NSTimeInterval WSSessionDefaultLifespan = 31556926;


@interface WASession ()
- (void)refreshCookie;
- (BOOL)tokenIsValid:(NSString*)string;
@end


@implementation WASession

- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n request:(WARequest*)req response:(WAResponse*)resp {
	self = [super init];
	database = db;
	name = [n copy];
	request = req;
	response = resp;
	
	WACookie *cookie = [request cookieForName:name];
	token = cookie.value;
	if(!cookie || ![self tokenIsValid:token])
		[self refreshCookie];
	
	return self;
}

- (BOOL)tokenIsValid:(NSString*)string {
	return ([database stringForQuery:@"SELECT rowid FROM tokens WHERE token = ?", string] != nil);
}
		 
- (void)refreshCookie {
	token = WAGenerateUUIDString();
	WACookie *cookie = [[WACookie alloc] initWithName:name value:token lifespan:WSSessionDefaultLifespan path:nil domain:nil];
	[response addCookie:cookie];
	[database executeUpdate:@"INSERT INTO tokens (token) VALUES (?)", token];
}

- (void)invalidate {
	[database close];
}

- (void)setValue:(id)value forKey:(NSString*)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
	[database executeUpdate:@"REPLACE INTO `values` (token, `key`, value) VALUES (?, ?, ?)", token, key, data];
}

- (id)valueForKey:(NSString*)key {
	NSData *data = [database dataForQuery:@"SELECT value FROM `values` WHERE token = ? AND `key` = ?", token, key];
	return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}

@end
