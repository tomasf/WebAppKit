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

@protocol WAServerDelegate
- (WARequestHandler*)server:(WAServer*)server handlerForRequest:(WARequest*)request;
@end


@interface WAServer : NSObject <AsyncSocketDelegate> {
	AsyncSocket *serverSocket;
	NSMutableSet *connections;
	
	id<WAServerDelegate> delegate;
	NSString *interface;
	NSUInteger port;
}

@property(assign) id<WAServerDelegate> delegate;

- (id)initWithPort:(NSUInteger)p interface:(NSString*)interfaceName delegate:(id<WAServerDelegate>)del;
- (BOOL)start:(NSError**)error;
@end