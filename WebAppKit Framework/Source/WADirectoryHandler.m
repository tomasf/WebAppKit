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


@interface WADirectoryHandler ()
@property(copy) NSString *directoryRoot;
@property(copy) NSString *requestPathRoot;
@end



@implementation WADirectoryHandler
@synthesize directoryRoot=_directoryRoot;
@synthesize requestPathRoot=_requestPathRoot;


- (id)initWithDirectory:(NSString*)root requestPath:(NSString*)path {
	if(!(self = [super init])) return nil;
	
	BOOL isDir;	
	if(![[NSFileManager defaultManager] fileExistsAtPath:root isDirectory:&isDir] || !isDir)
		NSLog(@"Warning: Directory %@ does not exist.", root);
	
	if(![path hasPrefix:@"/"])
		[NSException raise:NSInvalidArgumentException format:@"Request path must begin with '/'."];
	
	self.directoryRoot = root;
	self.requestPathRoot = path;
	if(![self.requestPathRoot hasSuffix:@"/"])
		self.requestPathRoot = [self.requestPathRoot stringByAppendingString:@"/"];
	
	return self;
}


- (NSString*)filePathForRequestPath:(NSString*)path {
	path = [path substringFromIndex:[self.requestPathRoot length]];
	return [self.directoryRoot stringByAppendingPathComponent:path];
}


- (BOOL)canHandleRequest:(WARequest *)req {
	NSString *path = req.path;
	if(![path hasPrefix:self.requestPathRoot]) return NO;
	
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