//
//  WSApplication.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//


#import "WARequestHandler.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WAServer.h"
@class WARoute;

extern int WAApplicationMain();


@interface WAApplication : NSObject <WSServerDelegate> {
	WAServer *server;
	
	NSMutableArray *requestHandlers;
	NSMutableSet *currentHandlers;
	
	NSMutableSet *routes;
	
	WARequest *request;
	WAResponse *response;
}

@property(readonly) WARequest *request;
@property(readonly) WAResponse *response;

+ (int)run;
- (id)initWithPort:(NSUInteger)port;
- (id)initWithPort:(NSUInteger)port interface:(NSString*)interface;

- (void)setup;

- (WARoute*)addRouteSelector:(SEL)sel HTTPMethod:(NSString*)method path:(NSString*)path;
- (WARoute*)routeForSelector:(SEL)selector;

- (void)addRequestHandler:(WARequestHandler*)handler;
- (void)removeRequestHandler:(WARequestHandler*)handler;

- (void)preprocess;
- (void)postprocess;
@end