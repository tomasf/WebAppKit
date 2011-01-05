//
//  WACookieSession.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASession.h"

@interface WACookieSession : WASession {
	NSString *name;
	NSData *encryptionKey;
	NSMutableDictionary *values;
}

- (id)initWithName:(NSString*)n encryptionKey:(NSData*)key request:(WARequest*)req response:(WAResponse*)resp;

@end
