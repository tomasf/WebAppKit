//
//  WACookieSessionManager.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WACookieSessionGenerator.h"
#import "WACookieSession.h"

@implementation WACookieSessionGenerator

- (id)initWithName:(NSString*)n encryptionKey:(NSData*)key {
	NSParameterAssert(n != nil);
	NSParameterAssert(key != nil);
	self = [super init];
	name = [n copy];
	encryptionKey = [key copy];
	return self;
}

- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response {
	return [[WACookieSession alloc] initWithName:name encryptionKey:encryptionKey request:request response:response];
}

@end
