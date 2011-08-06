//
//  WASQLiteSession.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASession.h"

@class WARequest, WAResponse, FMDatabase;

@interface WASession : NSObject {
	__weak WARequest *request;
	__weak WAResponse *response;
	
	NSString *name;
	NSString *token;
	FMDatabase *database;
}

@property(readonly) NSString *token;

- (id)valueForKey:(NSString*)key;
- (void)setValue:(id)value forKey:(NSString*)key;
- (void)removeValueForKey:(NSString*)key;
- (NSSet*)allKeys;

- (BOOL)validateRequestTokenForParameter:(NSString*)parameterName;
- (BOOL)validateRequestToken;
@end