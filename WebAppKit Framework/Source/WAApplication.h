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

@class WARoute, WARedirectHandler, WASessionGenerator, WASession;

extern int WAApplicationMain();


@interface WAApplication : NSObject <WAServerDelegate> {
	@private
	WAServer *server;
	
	NSMutableArray *requestHandlers;
	NSMutableSet *currentHandlers;
		
	WARequest *request;
	WAResponse *response;
	
	WASessionGenerator *standardSessionGenerator;
}

@property(readonly) WARequest *request;
@property(readonly) WAResponse *response;

@property(retain) WASessionGenerator *sessionGenerator;
@property(readonly) WASession *session;

+ (int)run;
- (id)initWithPort:(NSUInteger)port;
- (id)initWithPort:(NSUInteger)port interface:(NSString*)interface;

- (void)invalidate;

- (void)setup;

- (WARoute*)addRouteSelector:(SEL)sel HTTPMethod:(NSString*)method path:(NSString*)path;

- (void)addRequestHandler:(WARequestHandler*)handler;
- (void)removeRequestHandler:(WARequestHandler*)handler;

- (void)preprocess;
- (void)postprocess;

- (BOOL)validateRequestToken:(NSString*)parameterName forSession:(WASession*)session;
- (BOOL)validateRequestToken;
@end