//
//  WSCometApplication.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-23.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WACometStream.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WAJSON.h"

@implementation WACometStream

- (void)start {}
- (void)end {}

- (void)finish {
	[response finish];
}

- (void)handleRequest:(WARequest*)req response:(WAResponse*)resp {
	request = req;
	response = resp;
	response.progressive = YES;
	[resp setValue:@"close" forHeaderField:@"Connection"];
	
	[self start];	
	
	NSURL *URL = [[NSBundle bundleForClass:[WACometStream class]] URLForResource:@"CometPrefix" withExtension:@"html"];
	[response appendString:[NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:NULL]];
}

- (void)connectionDidClose {
	[self end];
}

- (void)sendMessage:(NSString*)message parameters:(NSDictionary*)params {
	NSString *string = [NSString stringWithFormat:@"<script>c(%@, %@);</script>\n", [message JSONValue], [params JSONValue] ?: @"null"];
	[response appendString:string];
}

- (void)sendMessage:(NSString*)message, ... {
	va_list list;
	va_start(list, message);
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	id key;
	while(key = va_arg(list, id)) {
		id value = va_arg(list, id);
		if(!value) continue;
		[params setObject:value forKey:key];
	}
	[self sendMessage:message parameters:params];
}


@end
