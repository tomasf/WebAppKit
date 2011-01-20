//
//  WAUploadedFile.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAUploadedFile.h"
#import "WAMultipartPart.h"

@interface WAUploadedFile (Private)
- (id)initWithPart:(WAMultipartPart*)part;
- (void)invalidate;
@end


@implementation WAUploadedFile
@synthesize temporaryFile, parameterName, mediaType, filename;


- (id)initWithPart:(WAMultipartPart*)part {
	self = [super init];
	NSString *disposition = [part.headerFields objectForKey:@"Content-Disposition"];
	NSDictionary *params = nil;
	WAExtractHeaderValueParameters(disposition, &params);
	
	parameterName = [params objectForKey:@"name"];
	if(!parameterName) return nil;
	
	filename = [params objectForKey:@"filename"];
	mediaType = [part.headerFields objectForKey:@"Content-Type"];
	temporaryFile = [part.temporaryFile copy];
	
	if(!temporaryFile) {
		temporaryFile = [NSTemporaryDirectory() stringByAppendingPathComponent:WAGenerateUUIDString()];
		[part.data writeToFile:temporaryFile atomically:NO];
	}
	
	return self;
}


- (NSString*)description {
	return [NSString stringWithFormat:@"<%@ %p, parameter: %@, filename: %@, type: %@, file: %@>", [self class], self, parameterName, filename, mediaType, temporaryFile];
}


- (void)finalize {
	[self invalidate];
	[super finalize];
}

- (void)invalidate {
	if(temporaryFile)
		[[NSFileManager defaultManager] removeItemAtPath:temporaryFile error:NULL];
	temporaryFile = nil;
}


- (BOOL)moveToPath:(NSString*)path error:(NSError**)outError {
	if(!temporaryFile) return NO;
	if(![[NSFileManager defaultManager] moveItemAtPath:temporaryFile toPath:path error:outError]) return NO;
	temporaryFile = nil;
	return YES;
}

@end