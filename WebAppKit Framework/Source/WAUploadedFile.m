//
//  WAUploadedFile.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAUploadedFile.h"
#import "WAMultipartPart.h"

@interface WAUploadedFile ()
@property(readwrite, copy) NSURL *temporaryFileURL;
@property(readwrite, copy) NSString *parameterName;
@property(readwrite, copy) NSString *filename;
@property(readwrite, copy) NSString *mediaType;
- (void)invalidate;
@end



@implementation WAUploadedFile
@synthesize temporaryFileURL=_temporaryFileURL;
@synthesize parameterName=_parameterName;
@synthesize filename=_filename;
@synthesize mediaType=_mediaType;


- (id)initWithPart:(WAMultipartPart*)part {
	if(!(self = [super init])) return nil;
	
	NSString *disposition = [part.headerFields objectForKey:@"Content-Disposition"];
	NSDictionary *params = nil;
	WAExtractHeaderValueParameters(disposition, &params);
	
	self.parameterName = [params objectForKey:@"name"];
	if(!self.parameterName) return nil;
	
	self.filename = [params objectForKey:@"filename"];
	self.mediaType = [part.headerFields objectForKey:@"Content-Type"];
	self.temporaryFileURL = [NSURL fileURLWithPath:part.temporaryFile];
	
	if(!self.temporaryFileURL) {
		self.temporaryFileURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:WAGenerateUUIDString()];
		if(![part.data writeToURL:self.temporaryFileURL atomically:NO])
			return nil;
	}
	
	return self;
}


- (NSString*)description {
	return [NSString stringWithFormat:@"<%@ %p, parameter: %@, filename: %@, type: %@, file: %@>", [self class], self, self.parameterName, self.filename, self.mediaType, self.temporaryFileURL.path];
}


- (void)finalize {
	[self invalidate];
	[super finalize];
}

- (void)invalidate {
	if(self.temporaryFileURL)
		[[NSFileManager defaultManager] removeItemAtURL:self.temporaryFileURL error:NULL];
	self.temporaryFileURL = nil;
}


- (BOOL)moveToURL:(NSURL*)destination error:(NSError**)outError {
	if(!self.temporaryFileURL) return NO;
	if(![[NSFileManager defaultManager] moveItemAtURL:self.temporaryFileURL toURL:destination error:outError]) return NO;
	self.temporaryFileURL = nil;
	return YES;
}

@end