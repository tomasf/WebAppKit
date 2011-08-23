//
//  WSConnection.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAServerConnection.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WARequestHandler.h"
#import "WAServer.h"
#import "WATemplate.h"


@interface WAResponse (Private)
- (id)initWithRequest:(WARequest*)req socket:(GCDAsyncSocket*)sock;
- (void)finishWithErrorString:(NSString*)error;
@property(copy) void(^completionHandler)(BOOL keepAlive);
@end

@interface WARequest (Private)
- (id)initWithHTTPMessage:(CFHTTPMessageRef)message;
- (id)initWithHeaderData:(NSData*)data;
- (void)readBodyFromSocket:(GCDAsyncSocket*)socket completionHandler:(void(^)(BOOL validity))handler;
- (void)invalidate;
@end

@interface WAServer (Private)
- (void)connectionDidClose:(WAServerConnection*)connection;
@end



@interface WAServerConnection ()
- (void)readNewRequest;
@end

enum {
	WAConnectionSocketTagHeader,
	WAConnectionSocketBodyHeader,
};


@implementation WAServerConnection

- (id)initWithSocket:(GCDAsyncSocket*)s server:(WAServer*)serv {
	self = [super init];
	server = serv;
	socket = s;
	[socket setDelegate:self];
	
	[self readNewRequest];
	return self;
}


- (void)readNewRequest {
	NSData *crlfcrlf = [NSData dataWithBytes:"\r\n\r\n" length:4];
	[socket readDataToData:crlfcrlf withTimeout:60 maxLength:100000 tag:WAConnectionSocketTagHeader];
}


- (void)onSocketDidDisconnect:(GCDAsyncSocket *)sock {
	[currentRequestHandler connectionDidClose];
	[server connectionDidClose:self];
	socket = nil;
}


- (void)handleRequest:(WARequest*)request {
	uint64_t start = WANanosecondTime();
	
	currentRequestHandler = [server.delegate server:server handlerForRequest:request];
	
	WAResponse *response = [[WAResponse alloc] initWithRequest:request socket:socket];
	response.completionHandler = ^(BOOL keepAlive) {
		uint64_t duration = WANanosecondTime()-start;
		if(WAGetDevelopmentMode())
			NSLog(@"%d %@ - %.02f ms", (int)response.statusCode, request.path, duration/1000000.0);
		currentRequestHandler = nil;
		[request invalidate];
		
		if(keepAlive)
			[self readNewRequest];
		else
			[socket disconnectAfterWriting];
	};
	

	@try {
		[currentRequestHandler handleRequest:request response:response socket:socket];
	}@catch(NSException *e) {
		WATemplate *template = [[WATemplate alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Exception" withExtension:@"wat"]];
		[template setValue:e forKey:@"exception"];
		[response finishWithErrorString:[template result]];
	}
}


- (void)handleRequestData:(NSData*)data {
	WARequest *request = [[WARequest alloc] initWithHeaderData:data];
	if(!request) {
		[socket disconnectAfterWriting];
		return;
	}
	
	[request readBodyFromSocket:socket completionHandler:^(BOOL validity) {
		[socket setDelegate:self];
		
		if(validity)
			[self handleRequest:request];
		else
			[socket disconnectAfterWriting];
	}];
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	if(tag == WAConnectionSocketTagHeader) {
		[self handleRequestData:data];
	}
}


@end