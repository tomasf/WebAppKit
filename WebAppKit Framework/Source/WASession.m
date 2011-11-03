//
//  WASQLiteSession.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASession.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WACookie.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseAdditions.h"

@interface WASession ()
- (void)refreshCookie;
- (BOOL)tokenIsValid:(NSString*)string;
@end


static const NSTimeInterval WASessionDefaultLifespan = 31556926;


@implementation WASession
@synthesize token;


- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n token:(NSString*)tokenString {
	if(!(self = [super init])) return nil;
	database = db;
	name = [n copy];
	token = [tokenString copy];
	
	if(![self tokenIsValid:token]) return nil;	
	return self;
}


- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n request:(WARequest*)req response:(WAResponse*)resp {
	if(!(self = [super init])) return nil;
	database = db;
	name = [n copy];
	request = req;
	response = resp;
	
	WACookie *cookie = [request cookieForName:name] ?: [[response cookies] objectForKey:name];
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
	WACookie *cookie = [[WACookie alloc] initWithName:name value:token lifespan:WASessionDefaultLifespan path:nil domain:nil];
	[response addCookie:cookie];
	[database executeUpdate:@"INSERT INTO tokens (token) VALUES (?)", token];
}


- (void)setValue:(id)value forKey:(NSString*)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
	if(![database executeUpdate:@"REPLACE INTO `values` (token, `key`, value) VALUES (?, ?, ?)", token, key, data])
		[NSException raise:@"WASessionException" format:@"Failed to update database: %@", [database lastErrorMessage]];
}


- (id)valueForKey:(NSString*)key {
	NSData *data = [database dataForQuery:@"SELECT value FROM `values` WHERE token = ? AND `key` = ?", token, key];
	return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}


- (void)removeValueForKey:(NSString*)key {
	[database executeUpdate:@"DELETE FROM `values` WHERE token = ? AND `key` = ?", token, key];
}


- (NSSet*)allKeys {
	FMResultSet *results = [database executeQuery:@"SELECT `key` FROM `values` WHERE token = ?", token];
	NSMutableSet *keys = [NSMutableSet set];
	while([results next])
		[keys addObject:[results stringForColumn:@"key"]];
	return keys;
}



#pragma mark CSRF token validation


- (BOOL)validateRequestTokenForParameter:(NSString*)parameterName {
	BOOL valid = [[request valueForPOSTParameter:parameterName] isEqual:self.token];
	if(!valid) {
		response.statusCode = 403;
		[response appendFormat:@"<h1>403 Forbidden: CSRF fault</h1>POST parameter '%@' did not match session token.", parameterName];
		[response finish];
	}
	return valid;
}

- (BOOL)validateRequestToken {
	return [self validateRequestTokenForParameter:@"WAKSessionToken"];
}



@end