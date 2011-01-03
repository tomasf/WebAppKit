//
//  WSSession.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-17.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@class WARequest, WAResponse, FMDatabase;


@interface WASession : NSObject {
	NSString *name;
	__weak WARequest *request;
	__weak WAResponse *response;

	NSString *token;
	FMDatabase *database;
}

- (void)setValue:(id)value forKey:(NSString*)key;
- (id)valueForKey:(NSString*)key;
@end