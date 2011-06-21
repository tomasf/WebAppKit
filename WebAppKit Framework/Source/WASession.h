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

- (id)initWithDatabase:(FMDatabase*)db name:(NSString*)n request:(WARequest*)req response:(WAResponse*)resp;
- (void)refreshCookie;
- (BOOL)tokenIsValid:(NSString*)string;
@end