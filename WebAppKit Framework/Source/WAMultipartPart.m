//
//  WAMultipartPart.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAMultipartPart.h"

static const uint64_t WAMultipartPartMaxBodyBufferLength = 1000000;

@interface WAMultipartPart ()
@property(readwrite, copy) NSDictionary *headerFields;
@property(readwrite, strong) NSMutableData *mutableData;
@property(readwrite, copy) NSString *temporaryFile;
@property(strong) NSFileHandle *fileHandle;
@end



@implementation WAMultipartPart

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
	
	self.headerFields = fields;
	self.mutableData = [NSMutableData data];
	return self;
}


- (NSData*)data {
	return self.mutableData;
}


- (void)switchToFile {
	self.temporaryFile = [NSTemporaryDirectory() stringByAppendingPathComponent:WAGenerateUUIDString()];
	[[NSFileManager defaultManager] createFileAtPath:self.temporaryFile contents:self.mutableData attributes:[NSDictionary dictionary]];
	self.mutableData = nil;
	self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.temporaryFile];
	[self.fileHandle seekToEndOfFile];
}


- (void)appendData:(NSData*)bodyData {
	if(self.mutableData) {
		[self.mutableData appendData:bodyData];
		if([self.mutableData length] > WAMultipartPartMaxBodyBufferLength) {
			[self switchToFile];
		}
	}else{
		[self.fileHandle writeData:bodyData];
	}
}

- (void)finish {
	if(self.fileHandle) {
		[self.fileHandle truncateFileAtOffset:[self.fileHandle offsetInFile]-2]; // strip CRLF
		[self.fileHandle closeFile];
		self.fileHandle = nil;
	}else{
		[self.mutableData setLength:[self.mutableData length]-2];
	}
}

@end