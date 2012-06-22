//
//  WAPrivate.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2012-03-06.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WAApplication.h"
#import "WAUploadedFile.h"
#import "WAResponse.h"
#import "WAServer.h"
@class WAMultipartPart;


@interface WAResponse (Private)
- (id)initWithRequest:(WARequest*)req socket:(GCDAsyncSocket*)sock;
- (void)finishWithErrorString:(NSString*)error;
@property(copy) void(^completionHandler)(BOOL keepAlive);
@end


@interface WARequest (Private)
- (id)initWithHTTPMessage:(id)message;
- (id)initWithHeaderData:(NSData*)data;
- (void)readBodyFromSocket:(GCDAsyncSocket*)socket completionHandler:(void(^)(BOOL validity))handler;
- (void)invalidate;
@end


@interface WAServer (Private)
- (void)connectionDidClose:(WAServerConnection*)connection;
@end


@interface WAApplication (Private)
- (void)setRequest:(WARequest*)req response:(WAResponse*)resp;
@end


@interface WAUploadedFile (Private)
- (id)initWithPart:(WAMultipartPart*)part;
- (void)invalidate;
@end