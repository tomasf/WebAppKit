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
#import "WAModuleManager.h"
#import "TFRegex.h"

static const NSString *WAHTTPServerPortKey = @"WAHTTPServerPort";
static const NSString *WAHTTPServerExternalAccessKey = @"WAHTTPServerExternalAccess";


int WAApplicationMain() {
	Class appClass = NSClassFromString([[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSPrincipalClass"]);
	if(!appClass) {
		NSLog(@"WAApplicationMain() requires NSPrincipalClass to be set in Info.plist. Set it to your WAApplication subclass or call +start yourself.");
		return 1;
	}
	return [appClass run];
}



@implementation WAApplication
@synthesize request, response;


+ (NSUInteger)port {
	NSUInteger port = [[[[NSBundle mainBundle] infoDictionary] objectForKey:WAHTTPServerPortKey] integerValue];
	if(!port) port = [[NSUserDefaults standardUserDefaults] integerForKey:@"port"];	
	if(!port) NSLog(@"No port number specified. Set WAHTTPServerPort in Info.plist or use the -port argument.");
	return port;
}


+ (BOOL)enableExternalAccess {
	return [[[[NSBundle mainBundle] infoDictionary] objectForKey:WAHTTPServerExternalAccessKey] boolValue];
}


+ (int)run {
	NSUInteger port = [self port];
	if(!port) return 1;
	NSString *interface = [self enableExternalAccess] ? nil : @"localhost";
	WAApplication *app = [[self alloc] initWithPort:port interface:interface];
	
	NSString *publicDir = [[NSBundle bundleForClass:self] pathForResource:@"public" ofType:nil]; 
	WADirectoryHandler *publicHandler = [[WADirectoryHandler alloc] initWithDirectory:publicDir requestPath:@"/"];
	[app addRequestHandler:publicHandler];
	
	for(WARequestHandler *handler in [[WAModuleManager sharedManager] allRequestHandlers])
		[app addRequestHandler:handler];
	
	NSLog(@"WebAppKit started on port %d", (int)port);
	
	for(;;)
		[[NSRunLoop currentRunLoop] run];
}



- (id)initWithPort:(NSUInteger)port interface:(NSString*)interface {
	self = [super init];
	requestHandlers = [NSMutableArray array];
	server = [[WAServer alloc] initWithPort:port interface:interface delegate:self];
	currentHandlers = [NSMutableSet set];
	
	NSError *error;
	if(![server start:&error]) {
		NSLog(@"Failed to start server: %@", error);
		return nil;
	}
	
	[self setup];
	return self;
}

- (id)initWithPort:(NSUInteger)port {
	return [self initWithPort:port interface:@"localhost"];
}


- (void)setup {}


#pragma mark Request Handlers


- (void)addRequestHandler:(WARequestHandler*)handler {
	[requestHandlers addObject:handler];
}


- (void)removeRequestHandler:(WARequestHandler*)handler {
	[requestHandlers removeObject:handler];
}


- (NSString*)fileNotFoundFile {
	return [[NSBundle bundleForClass:[WAApplication class]] pathForResource:@"404" ofType:@"html"];
}


- (WARequestHandler*)fallbackHandler {
	return [[WAStaticFileHandler alloc] initWithFile:[self fileNotFoundFile] enableCaching:NO];
}


- (WARequestHandler*)handlerForRequest:(WARequest*)req {
	for(WARequestHandler *handler in requestHandlers)
		if([handler canHandleRequest:req])
			return [handler handlerForRequest:req];
	return [self fallbackHandler];
}


- (WARequestHandler*)server:(WAServer*)server handlerForRequest:(WARequest*)req {
	return [self handlerForRequest:req];
}



#pragma mark Routes


- (TFRegex*)regexForPathExpression:(NSString*)path {
	NSMutableArray *newComponents = [NSMutableArray array];
	for(NSString *component in [path pathComponents]) {
		if([component isEqual:@"*"]){
			[newComponents addObject:@"([[:alnum:]_-]+)"];
		}else{
			[newComponents addObject:[TFRegex escapeString:component]];
		}
	}
	
	NSString *re = [NSString stringWithFormat:@"^%@$", [NSString pathWithComponents:newComponents]];
	return [[TFRegex alloc] initWithPattern:re options:0];
}


- (void)addRouteSelector:(SEL)sel HTTPMethod:(NSString*)method path:(NSString*)path {
	if(![self respondsToSelector:sel])
		NSLog(@"Warning: %@ doesn't respond to route handler message '%@'.", self, NSStringFromSelector(sel));

	TFRegex *regex = [self regexForPathExpression:path];
	[requestHandlers addObject:[[WARoute alloc] initWithPathExpression:regex method:method target:self action:sel]];
}

- (void)setRequest:(WARequest*)req response:(WAResponse*)resp {
	request = req;
	response = resp;
}

- (void)preprocess {}
- (void)postprocess {}



@end