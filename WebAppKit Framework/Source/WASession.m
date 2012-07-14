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


@interface WASession ()
@property(weak) WARequest *request;
@property(weak) WAResponse *response;

@property(copy) NSString *name;
@property(copy, readwrite) NSString *token;
@property(strong) FMDatabase *database;
@end



@implementation WASession
@synthesize request=_request;
@synthesize response=_response;
@synthesize name=_name;
@synthesize token=_token;
@synthesize database=_database;


- (id)initWithDatabase:(FMDatabase*)database name:(NSString*)name token:(NSString*)token {
	if(!(self = [super init])) return nil;
	self.database = database;
	self.name = name;
	self.token = token;
	
	if(![self tokenIsValid:self.token]) return nil;	
	return self;
}


- (id)initWithDatabase:(FMDatabase*)database name:(NSString*)name request:(WARequest*)request response:(WAResponse*)response {
	if(!(self = [super init])) return nil;
	
	self.database = database;
	self.name = name;
	self.request = request;
	self.response = response;
	
	WACookie *cookie = [request cookieForName:name] ?: [[response cookies] objectForKey:name];
	self.token = cookie.value;
	if(!cookie || ![self tokenIsValid:self.token])
		[self refreshCookie];
	
	return self;
}


- (BOOL)tokenIsValid:(NSString*)string {
	return ([self.database stringForQuery:@"SELECT rowid FROM tokens WHERE token = ?", string] != nil);
}


- (void)refreshCookie {
	self.token = WAGenerateUUIDString();
	WACookie *cookie = [[WACookie alloc] initWithName:self.name value:self.token lifespan:WASessionDefaultLifespan path:nil domain:nil];
	[self.response addCookie:cookie];
	[self.database executeUpdate:@"INSERT INTO tokens (token) VALUES (?)", self.token];
}


- (void)setValue:(id)value forKey:(NSString*)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
	if(![self.database executeUpdate:@"REPLACE INTO `values` (token, `key`, value) VALUES (?, ?, ?)", self.token, key, data])
		[NSException raise:@"WASessionException" format:@"Failed to update database: %@", [self.database lastErrorMessage]];
}


- (id)valueForKey:(NSString*)key {
	NSData *data = [self.database dataForQuery:@"SELECT value FROM `values` WHERE token = ? AND `key` = ?", self.token, key];
	return data ? [NSKeyedUnarchiver unarchiveObjectWithData:data] : nil;
}


- (void)setObject:(id)value forKeyedSubscript:(id)key {
	[self setValue:value forKey:key];
}


- (id)objectForKeyedSubscript:(id)key {
	return [self valueForKey:key];
}


- (void)removeValueForKey:(NSString*)key {
	[self.database executeUpdate:@"DELETE FROM `values` WHERE token = ? AND `key` = ?", self.token, key];
}


- (NSSet*)allKeys {
	FMResultSet *results = [self.database executeQuery:@"SELECT `key` FROM `values` WHERE token = ?", self.token];
	NSMutableSet *keys = [NSMutableSet set];
	while([results next])
		[keys addObject:[results stringForColumn:@"key"]];
	return keys;
}



#pragma mark CSRF token validation


- (BOOL)validateRequestTokenForParameter:(NSString*)parameterName {
	BOOL valid = [[self.request valueForBodyParameter:parameterName] isEqual:self.token];
	if(!valid) {
		self.response.statusCode = 403;
		[self.response appendFormat:@"<h1>403 Forbidden: CSRF fault</h1>Parameter '%@' did not match session token.", parameterName];
		[self.response finish];
	}
	return valid;
}


- (BOOL)validateRequestToken {
	return [self validateRequestTokenForParameter:@"WAKSessionToken"];
}


@end