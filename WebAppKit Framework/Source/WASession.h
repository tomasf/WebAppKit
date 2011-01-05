//
//  WSSession.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-17.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@class WARequest, WAResponse, FMDatabase;


@interface WASession : NSObject {
	__weak WARequest *request;
	__weak WAResponse *response;
}

- (void)setValue:(id)value forKey:(NSString*)key;
- (id)valueForKey:(NSString*)key;
- (void)removeValueForKey:(NSString*)key;
@end