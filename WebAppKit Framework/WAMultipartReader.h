//
//  WAMultipartReader.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class WAMultipartReader, WAMultipartPart, GCDAsyncSocket;
#import "GCDAsyncSocket.h"

@protocol WAMultipartReaderDelegate
- (void)multipartReader:(WAMultipartReader*)reader finishedWithParts:(NSArray*)parts;
- (void)multipartReaderFailed:(WAMultipartReader*)reader;
@end



@interface WAMultipartReader : NSObject <GCDAsyncSocketDelegate> {
	id<WAMultipartReaderDelegate> delegate;
	id oldSocketDelegate;
	GCDAsyncSocket *socket;
	NSString *boundary;
	
	NSMutableArray *parts;
	WAMultipartPart *currentPart;
}

- (id)initWithSocket:(GCDAsyncSocket*)sock boundary:(NSString*)boundaryString delegate:(id<WAMultipartReaderDelegate>)del;

@end
