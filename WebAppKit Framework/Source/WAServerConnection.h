//
//  WSConnection.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//


#import "GCDAsyncSocket.h"

@class WAServer, WARequestHandler, WARequest, WAResponse;


@interface WAServerConnection : NSObject <GCDAsyncSocketDelegate> {
	GCDAsyncSocket *socket;
	WAServer *server;
	
	WARequestHandler *currentRequestHandler;
}

- (id)initWithSocket:(GCDAsyncSocket*)s server:(WAServer*)serv;
@end