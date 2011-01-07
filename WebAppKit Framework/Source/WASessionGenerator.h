//
//  WASessionManager.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class WASession, WARequest, WAResponse;

@interface WASessionGenerator : NSObject {
}

+ (id)databaseStorageManagerWithName:(NSString*)n;
+ (id)clientStorageManagerWithName:(NSString*)n encryptionKey:(NSData*)key;

- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response;
- (void)invalidate;

@end