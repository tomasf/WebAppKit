//
//  WSServer.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "AsyncSocket.h"
#import "WAServerConnection.h"

@class WARequest, WARequestHandler, WAServer;

@protocol WSServerDelegate
- (WARequestHandler*)server:(WAServer*)server handlerForRequest:(WARequest*)request;
@end


@interface WAServer : NSObject <AsyncSocketDelegate> {
	AsyncSocket *serverSocket;
	NSMutableSet *connections;
	
	id<WSServerDelegate> delegate;
	NSString *interface;
	NSUInteger port;
}

@property(assign) id<WSServerDelegate> delegate;

- (id)initWithPort:(NSUInteger)p interface:(NSString*)interfaceName delegate:(id<WSServerDelegate>)del;
- (BOOL)start:(NSError**)error;
@end