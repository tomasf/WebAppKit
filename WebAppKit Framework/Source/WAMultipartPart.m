//
//  WAMultipartPart.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAMultipartPart.h"

static const uint64_t WAMultipartPartMaxBodyBufferLength = 1000000;


@implementation WAMultipartPart
@synthesize headerFields, data, temporaryFile;

- (id)initWithHeaderData:(NSData*)headerData {
	self = [super init];
	NSString *string = [[NSString alloc] initWithData:headerData encoding:NSUTF8StringEncoding];
	if(!string) return nil;
	
	NSArray *fieldStrings = [string componentsSeparatedByString:@"\r\n"];
	NSMutableDictionary *fields = [NSMutableDictionary dictionary];
	for(NSString *fieldString in fieldStrings) {
		NSInteger split = [fieldString rangeOfString:@": "].location;
		if(split == NSNotFound) continue;
		NSString *key = [fieldString substringToIndex:split];
		NSString *value = [fieldString substringFromIndex:split+2];
		[fields setObject:value forKey:key];
	}
	
	headerFields = fields;
	data = [NSMutableData data];
	return self;
}


- (void)switchToFile {
	temporaryFile = [NSTemporaryDirectory() stringByAppendingPathComponent:WAGenerateUUIDString()];
	[[NSFileManager defaultManager] createFileAtPath:temporaryFile contents:data attributes:[NSDictionary dictionary]];
	data = nil;
	fileHandle = [NSFileHandle fileHandleForWritingAtPath:temporaryFile];
	[fileHandle seekToEndOfFile];
}


- (void)appendData:(NSData*)bodyData {
	if(data) {
		[data appendData:bodyData];
		if([data length] > WAMultipartPartMaxBodyBufferLength) {
			[self switchToFile];
		}
	}else{
		[fileHandle writeData:bodyData];
	}
}

- (void)finish {
	if(fileHandle) {
		[fileHandle truncateFileAtOffset:[fileHandle offsetInFile]-2]; // strip CRLF
		[fileHandle closeFile];
		fileHandle = nil;
	}else{
		[data setLength:[data length]-2];
	}
}

@end