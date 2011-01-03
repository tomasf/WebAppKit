//
//  WSConnection.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//


#import "AsyncSocket.h"

@class WAServer, WARequestHandler, WARequest, WAResponse;


@interface WAServerConnection : NSObject <AsyncSocketDelegate> {
	AsyncSocket *socket;
	WAServer *server;
	
	WARequestHandler *currentRequestHandler;
}

- (id)initWithSocket:(AsyncSocket*)s server:(WAServer*)serv;
@end