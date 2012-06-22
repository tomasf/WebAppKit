//
//  WSServer.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-09.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "GCDAsyncSocket.h"
#import "WAServerConnection.h"

@class WARequest, WARequestHandler;


@interface WAServer : NSObject
@property(copy) WARequestHandler*(^requestHandlerFactory)(WARequest *request);

- (id)initWithPort:(NSUInteger)p interface:(NSString*)interfaceName;
- (BOOL)start:(NSError**)error;
- (void)invalidate;
@end