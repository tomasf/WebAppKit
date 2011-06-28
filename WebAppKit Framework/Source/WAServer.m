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

@implementation WAServer
@synthesize delegate;


- (id)initWithPort:(NSUInteger)p interface:(NSString*)interfaceName delegate:(id<WAServerDelegate>)del {
	self = [super init];
	delegate = del;
	port = p;
	interface = [interfaceName copy];
	connections = [NSMutableSet set];
	serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	return self;
}


- (BOOL)start:(NSError**)error {
	return [serverSocket acceptOnInterface:interface port:port error:error];
}

- (void)invalidate {
	[serverSocket disconnect];
	serverSocket = nil;
}


- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	WAServerConnection *connection = [[WAServerConnection alloc] initWithSocket:newSocket server:self];
	[connections addObject:connection];
}

- (void)connectionDidClose:(WAServerConnection*)connection {
	[connections removeObject:connection];
}

@end