//
//  WSCometApplication.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-23.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@class WARequest, WAResponse;
#import "WARequestHandler.h"


@interface WACometStream : WARequestHandler {
	WARequest *request;
	WAResponse *response;
}

- (void)start;
- (void)end;
- (void)finish;
- (void)sendMessage:(NSString*)message parameters:(NSDictionary*)params;
- (void)sendMessage:(NSString*)message, ...;
@end