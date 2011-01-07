//
//  WACookieSessionManager.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionGenerator.h"

@interface WACookieSessionGenerator : WASessionGenerator {
	NSString *name;
	NSData *encryptionKey;
}

- (id)initWithName:(NSString*)n encryptionKey:(NSData*)key;

@end
