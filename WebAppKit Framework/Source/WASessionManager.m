//
//  WASessionManager.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionManager.h"
#import "WASQLiteSessionManager.h"
#import "WACookieSessionManager.h"

@implementation WASessionManager

+ (id)databaseStorageManagerWithName:(NSString*)name {
	return [[WASQLiteSessionManager alloc] initWithName:name];
}


+ (id)clientStorageManagerWithName:(NSString*)name encryptionKey:(NSData*)key {
	return [[WACookieSessionManager alloc] initWithName:name encryptionKey:key];
}


- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response {return nil;}
- (void)invalidate {}
@end