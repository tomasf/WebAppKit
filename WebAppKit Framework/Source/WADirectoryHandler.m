//
//  WSDirectoryHandler.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-11.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WADirectoryHandler.h"
#import "WARequest.h"
#import "WAResponse.h"
#import "WAStaticFileHandler.h"


@implementation WADirectoryHandler

- (id)initWithDirectory:(NSString*)root requestPath:(NSString*)path {
	self = [super init];
	
	BOOL isDir;	
	if(![[NSFileManager defaultManager] fileExistsAtPath:root isDirectory:&isDir] || !isDir)
		NSLog(@"Warning: Directory %@ does not exist.", root);
	
	if(![path hasPrefix:@"/"])
		[NSException raise:NSInvalidArgumentException format:@"Request path must begin with '/'."];
	
	directoryRoot = [root copy];
	requestPathRoot = [path copy];
	if(![requestPathRoot hasSuffix:@"/"])
		requestPathRoot = [requestPathRoot stringByAppendingString:@"/"];
	return self;
}


- (NSString*)filePathForRequestPath:(NSString*)path {
	path = [path substringFromIndex:[requestPathRoot length]];
	return [directoryRoot stringByAppendingPathComponent:path];
}


- (BOOL)canHandleRequest:(WARequest *)req {
	NSString *path = req.path;
	if(![path hasPrefix:requestPathRoot]) return NO;
	
	NSString *filePath = [self filePathForRequestPath:path];
	BOOL isDir;
	if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir] || isDir) return false;
	for(NSString *component in [filePath pathComponents])
		if([component hasPrefix:@"."]) return NO; // Disallow invisible files
	return YES;
}


- (void)handleRequest:(WARequest *)req response:(WAResponse *)resp {
	NSString *filePath = [self filePathForRequestPath:req.path];
	
	WAStaticFileHandler *fileHandler = [[WAStaticFileHandler alloc] initWithFile:filePath enableCaching:YES];
	[fileHandler handleRequest:req response:resp];
}

@end
