//
//  WSServer.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAServer.h"
#import "GCDAsyncSocket.h"
#import "WAServerConnection.h"
#import "WARequestHandler.h"


@interface WAServer () <GCDAsyncSocketDelegate>
@property(strong) GCDAsyncSocket *socket;
@property(strong) NSMutableSet *connections;

@property(copy) NSString *interface;
@property NSUInteger port;
@end


@implementation WAServer
@synthesize socket=_socket;
@synthesize connections=_connections;
@synthesize requestHandlerFactory=_requestHandlerFactory;
@synthesize interface=_interface;
@synthesize port=_port;


- (id)initWithPort:(NSUInteger)port interface:(NSString*)interface {
	if(!(self = [super init])) return nil;
	
	self.port = port;
	self.interface = interface;
	
	self.connections = [NSMutableSet set];
	self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	return self;
}


- (BOOL)start:(NSError**)error {
	return [self.socket acceptOnInterface:self.interface port:self.port error:error];
}


- (void)invalidate {
	[self.socket disconnect];
	self.socket = nil;
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	NSAssert(self.requestHandlerFactory != nil, @"requestHandlerFactory not set!");
	WAServerConnection *connection = [[WAServerConnection alloc] initWithSocket:newSocket server:self];
	[self.connections addObject:connection];
}


- (void)connectionDidClose:(WAServerConnection*)connection {
	[self.connections removeObject:connection];
}


@end