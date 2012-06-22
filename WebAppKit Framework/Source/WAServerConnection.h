//
//  WSConnection.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@class WAServer, GCDAsyncSocket;


@interface WAServerConnection : NSObject
- (id)initWithSocket:(GCDAsyncSocket*)socket server:(WAServer*)server;
@end