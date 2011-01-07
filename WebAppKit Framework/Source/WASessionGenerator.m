//
//  WASessionManager.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionGenerator.h"
#import "WASQLiteSessionGenerator.h"
#import "WACookieSessionGenerator.h"

@implementation WASessionGenerator

+ (id)databaseStorageGeneratorWithName:(NSString*)name {
	return [[WASQLiteSessionGenerator alloc] initWithName:name];
}


+ (id)clientStorageGeneratorWithName:(NSString*)name encryptionKey:(NSData*)key {
	return [[WACookieSessionGenerator alloc] initWithName:name encryptionKey:key];
}


- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response {return nil;}
- (void)invalidate {}
@end