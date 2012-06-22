//
//  WAMultipartPart.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//


@interface WAMultipartPart : NSObject {
	NSDictionary *headerFields;
	NSMutableData *data;
	NSString *temporaryFile;
	NSFileHandle *fileHandle;
}

- (id)initWithHeaderData:(NSData*)headerData;
- (void)appendData:(NSData*)bodyData;
- (void)finish;

@property(readonly) NSDictionary *headerFields;
@property(readonly) NSData *data;
@property(readonly) NSString *temporaryFile;
@end