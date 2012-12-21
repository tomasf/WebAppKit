//
//  WAMultipartPart.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//


@interface WAMultipartPart : NSObject
- (id)initWithHeaderData:(NSData*)headerData;
- (void)appendData:(NSData*)bodyData;
- (void)finish;

@property(readonly, copy) NSDictionary *headerFields;
@property(readonly, copy) NSData *data;
@property(readonly, copy) NSString *temporaryFile;
@end