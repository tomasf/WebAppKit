//
//  WSStaticFileHandler.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-11.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAStaticFileHandler.h"
#import "WAResponse.h"
#import "WARequest.h"

@implementation WAStaticFileHandler

- (id)initWithFile:(NSString*)path enableCaching:(BOOL)useHTTPCache {
	self = [super init];
	file = [path copy];
	enableCaching = useHTTPCache;
	return self;
}


// We use this instead of -[NSWorkspace typeOfFile:error:] because NSWorkspace is in AppKit.
+ (NSString*)UTIForFile:(NSString*)file {
	FSRef ref;
	if(FSPathMakeRef((const uint8_t*)[file fileSystemRepresentation], &ref, false) != noErr) return nil;
	NSDictionary *values = nil;
	if(LSCopyItemAttributes(&ref, kLSRolesViewer, (CFArrayRef)[NSArray arrayWithObject:(id)kLSItemContentType], (CFDictionaryRef*)&values) != noErr) return nil;
	NSMakeCollectable(values);
	return [values objectForKey:(id)kLSItemContentType];
}


+ (NSString*)mediaTypeForFile:(NSString*)file {
	NSString *defaultType = @"application/octet-stream";
	NSString *UTI = [self UTIForFile:file];
	if(!UTI) return defaultType;
	NSString *mediaType = (NSString*)UTTypeCopyPreferredTagWithClass((CFStringRef)UTI, kUTTagClassMIMEType);
	if(!mediaType) return defaultType;
	return NSMakeCollectable(mediaType);
}


- (void)handleRequest:(WARequest *)req response:(WAResponse *)resp {
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
	NSDate *modificationDate = [attributes fileModificationDate];
		
	BOOL notModified = req.conditionalModificationDate && [req.conditionalModificationDate timeIntervalSinceDate:modificationDate] >= 0;
	
	if(notModified && enableCaching) {
		resp.statusCode = 304;
		resp.hasBody = NO;
		[resp finish];
		return;
	}
	
	resp.mediaType = [[self class] mediaTypeForFile:file];
	if(enableCaching) resp.modificationDate = modificationDate;
	
	[resp appendBodyData:[NSData dataWithContentsOfFile:file]];
	[resp finish];
}

@end