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
#import "WAPrivate.h"
#import "GCDAsyncSocket.h"


@interface WAServerConnection () <GCDAsyncSocketDelegate> 
@property(strong) GCDAsyncSocket *socket;
@property(weak) WAServer *server;
@property(strong) WARequestHandler *currentRequestHandler;

- (void)readNewRequest;
@end


@implementation WAServerConnection


- (id)initWithSocket:(GCDAsyncSocket*)socket server:(WAServer*)server {
	if(!(self = [super init])) return nil;
	
	self.server = server;
	self.socket = socket;
	self.socket.delegate = self;
	
	[self readNewRequest];
	return self;
}


- (void)readNewRequest {
	NSData *crlfcrlf = [NSData dataWithBytes:"\r\n\r\n" length:4];
	[self.socket readDataToData:crlfcrlf withTimeout:60 maxLength:100000 tag:0];
}


- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
	[self.currentRequestHandler connectionDidClose];
	[self.server connectionDidClose:self];
	self.socket = nil;
}


- (void)handleRequest:(WARequest*)request {
	uint64_t start = WANanosecondTime();
	
	self.currentRequestHandler = self.server.requestHandlerFactory(request);
	
	WAResponse *response = [[WAResponse alloc] initWithRequest:request socket:self.socket];
	__weak WAResponse *weakResponse = response;
	
	response.completionHandler = ^(BOOL keepAlive) {
		uint64_t duration = WANanosecondTime()-start;
		if(WAGetDevelopmentMode())
			NSLog(@"%d %@ - %.02f ms", (int)weakResponse.statusCode, request.path, duration/1000000.0);
		self.currentRequestHandler = nil;
		[request invalidate];
		
		if(keepAlive)
			[self readNewRequest];
		else
			[self.socket disconnectAfterWriting];
	};
	

	@try {
		[self.currentRequestHandler handleRequest:request response:response socket:self.socket];
	}@catch(NSException *e) {
		WATemplate *template = [[WATemplate alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"Exception" withExtension:@"wat"]];
		[template setValue:e forKey:@"exception"];
		[response finishWithErrorString:[template result]];
	}
}


- (void)handleRequestData:(NSData*)data {
	WARequest *request = [[WARequest alloc] initWithHeaderData:data];
	if(!request) {
		[self.socket disconnectAfterWriting];
		return;
	}
	
	[request readBodyFromSocket:self.socket completionHandler:^(BOOL validity) {
		[self.socket setDelegate:self];
		
		if(validity)
			[self handleRequest:request];
		else
			[self.socket disconnectAfterWriting];
	}];
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag {
	[self handleRequestData:data];
}


@end