//
//  WSApplication.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAApplication.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WARoute.h"
#import "WAServerConnection.h"
#import "WAServer.h"
#import "WADirectoryHandler.h"
#import "WAStaticFileHandler.h"
#import "WASession.h"
#import "WASessionGenerator.h"

static const NSString *WAHTTPServerPortKey = @"WAHTTPServerPort";
static const NSString *WAHTTPServerExternalAccessKey = @"WAHTTPServerExternalAccess";


int WAApplicationMain() {
	@autoreleasepool {
		Class appClass = NSClassFromString([[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSPrincipalClass"]);
		if(!appClass) {
			NSLog(@"WAApplicationMain() requires NSPrincipalClass to be set in Info.plist. Set it to your WAApplication subclass or call +run yourself.");
			return 1;
		}
		return [appClass run];
	}
}



@interface WAApplication ()
@property(strong, nonatomic) WAServer *server;

@property(strong) NSMutableArray *requestHandlers;
@property(strong) NSMutableSet *currentHandlers;

@property(strong, readwrite) WARequest *request;
@property(strong, readwrite) WAResponse *response;

- (WARequestHandler*)handlerForRequest:(WARequest*)req;
@end



@implementation WAApplication
@synthesize server=_server;
@synthesize requestHandlers=_requestHandlers;
@synthesize currentHandlers=_currentHandlers;
@synthesize request=_request;
@synthesize response=_response;
@synthesize sessionGenerator=_sessionGenerator;


+ (uint16_t)port {
	NSUInteger port = [[[[NSBundle mainBundle] infoDictionary] objectForKey:WAHTTPServerPortKey] unsignedShortValue];
	if(!port) port = [[NSUserDefaults standardUserDefaults] integerForKey:@"port"];	
	if(!port) NSLog(@"No port number specified. Set WAHTTPServerPort in Info.plist or use the -port argument.");
	return port;
}


+ (BOOL)enableExternalAccess {
	return [[[[NSBundle mainBundle] infoDictionary] objectForKey:WAHTTPServerExternalAccessKey] boolValue];
}


+ (int)run {
	uint16_t port = [self port];
	if(!port) return EXIT_FAILURE;
	NSString *interface = [self enableExternalAccess] ? nil : @"localhost";
	
	WAApplication *app = [[self alloc] init];
	app.server = [[WAServer alloc] initWithPort:port interface:interface];
	
	NSString *publicDir = [[NSBundle bundleForClass:self] pathForResource:@"public" ofType:nil]; 
	WADirectoryHandler *publicHandler = [[WADirectoryHandler alloc] initWithDirectory:publicDir requestPath:@"/"];
	[app addRequestHandler:publicHandler];
	
	NSError *error;
	if(![app start:&error]) {
		NSLog(@"*** Exiting. [%@ start:] failed: %@", NSStringFromClass(self), error);
		return EXIT_FAILURE;
	}
	
	NSLog(@"WebAppKit started on port %hu", port);
	NSLog(@"http://localhost:%hu/", port);
	
	for(;;) @autoreleasepool {
		[[NSRunLoop currentRunLoop] run];
	}
}


- (id)init {
	if(!(self = [super init])) return nil;

	self.requestHandlers = [NSMutableArray array];	
	self.currentHandlers = [NSMutableSet set];
	
	[self setup];
	return self;
}


- (void)setServer:(WAServer *)server {
	_server = server;
	
	__weak WAApplication *weakSelf = self;
	self.server.requestHandlerFactory = ^(WARequest *request){
		return [weakSelf handlerForRequest:request];
	};
}


- (BOOL)start:(NSError**)error {
	return [self.server start:error];
}


- (void)invalidate {
	[self.server invalidate];
	self.server = nil;
	[self.sessionGenerator invalidate];
	self.sessionGenerator = nil;
}


- (void)setup {}


#pragma mark Request Handlers


- (WARequestHandler*)handlerForRequest:(WARequest*)req {
	for(WARequestHandler *handler in self.requestHandlers)
		if([handler canHandleRequest:req])
			return [handler handlerForRequest:req];
	return [self fallbackHandler];
}


- (void)addRequestHandler:(WARequestHandler*)handler {
	[self.requestHandlers addObject:handler];
}


- (void)removeRequestHandler:(WARequestHandler*)handler {
	[self.requestHandlers removeObject:handler];
}


- (NSString*)fileNotFoundFile {
	return [[NSBundle bundleForClass:[WAApplication class]] pathForResource:@"404" ofType:@"html"];
}


- (WARequestHandler*)fallbackHandler {
	WAStaticFileHandler *handler = [[WAStaticFileHandler alloc] initWithFile:[self fileNotFoundFile] enableCaching:NO];
	handler.statusCode = 404;
	return handler;
}



#pragma mark Routes


- (WARoute*)addRouteSelector:(SEL)sel HTTPMethod:(NSString*)method path:(NSString*)path {
	if(![self respondsToSelector:sel])
		NSLog(@"Warning: %@ doesn't respond to route handler message '%@'.", self, NSStringFromSelector(sel));

	WARoute *route = [WARoute routeWithPathExpression:path method:method target:self action:sel];
	
	[self addRequestHandler:route];
	return route;
}


- (void)setRequest:(WARequest*)req response:(WAResponse*)resp {
	self.request = req;
	self.response = resp;
}


- (void)preprocess {}
- (void)postprocess {}


- (WASession*)session {
	if(!self.sessionGenerator)
		[NSException raise:NSGenericException format:@"The session property cannot be used without first setting a sessionGenerator."];
	return [self.sessionGenerator sessionForRequest:self.request response:self.response];
}


@end