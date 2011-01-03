//
//  WSSessionStore.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-18.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@class FMDatabase, WASession, WARequest, WAResponse;


@interface WASessionStore : NSObject {
	NSString *name;
	FMDatabase *database;
}

- (id)initWithName:(NSString*)n;
- (void)invalidate;
- (WASession*)sessionForRequest:(WARequest*)request response:(WAResponse*)response;

@end
