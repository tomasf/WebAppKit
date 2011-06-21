//
//  WASQLiteSessionManager.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WASessionGenerator.h"

@class FMDatabase, WASession, WARequest, WAResponse;


@interface WASessionGenerator : NSObject {
	NSString *name;
	FMDatabase *database;
}

- (id)initWithName:(NSString*)n;
- (void)invalidate;

- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response;
@end