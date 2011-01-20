//
//  WAMultipartReader.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAMultipartReader.h"
#import "WAMultipartPart.h"
#import "AsyncSocket.h"

enum {
	WAMPRInitialBoundary,
	WAMPRPartHeader,
	WAMPRPartBodyChunk,
};

static const uint64_t WAMPRMaxPartHeaderLength = 10000;
static const uint64_t WAMPRMaxPartBodyChunkLength = 10000;

@interface WAMultipartReader ()
- (void)readInitialBoundary;
@end



@implementation WAMultipartReader

- (id)initWithSocket:(AsyncSocket*)sock boundary:(NSString*)boundaryString delegate:(id<WAMultipartReaderDelegate>)del {
	self = [super init];
	delegate = del;
	socket = sock;
	oldSocketDelegate = [socket delegate];
	[socket setDelegate:self];
	boundary = [boundaryString copy];
	parts = [NSMutableArray array];
	[self readInitialBoundary];
	return self;
}


- (void)fail {
	[socket setDelegate:oldSocketDelegate];
	[delegate multipartReaderFailed:self];
}


- (void)readInitialBoundary {
	[socket readDataToData:[AsyncSocket CRLFData] withTimeout:10 maxLength:[boundary length]+4 tag:WAMPRInitialBoundary];
}


- (void)readPartHeader {
	NSData *terminator = [NSData dataWithBytes:"\r\n\r\n" length:4];
	[socket readDataToData:terminator withTimeout:10 maxLength:WAMPRMaxPartHeaderLength tag:WAMPRPartHeader];
}


- (void)readPartBody {
	[socket readDataToData:[AsyncSocket CRLFData] withTimeout:60 maxLength:WAMPRMaxPartBodyChunkLength tag:WAMPRPartBodyChunk];
}

- (void)finishPart {
	[currentPart finish];
	[parts addObject:currentPart];
	currentPart = nil;
}

- (void)finish {
	[delegate multipartReader:self finishedWithParts:parts];
}


- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if(tag == WAMPRInitialBoundary) {
		NSString *correctString = [NSString stringWithFormat:@"--%@\r\n", boundary];
		NSString *givenString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if(![givenString isEqual:correctString])
			return [self fail];
		
		[self readPartHeader];
	
	}else if(tag == WAMPRPartHeader) {
		currentPart = [[WAMultipartPart alloc] initWithHeaderData:data];
		if(!currentPart) return [self fail];
		[self readPartBody];
		
	}else if(tag == WAMPRPartBodyChunk) {
		NSData *boundaryData = [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]; 
		NSData *boundaryEndData = [[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]; 
		if([data isEqual:boundaryData]) {
			[self finishPart];
			[self readPartHeader];
		}else if([data isEqual:boundaryEndData]){
			[self finishPart];
			[self finish];
		}else{
			[currentPart appendData:data];
			[self readPartBody];
		}
	}
}



@end
