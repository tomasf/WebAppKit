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


+ (NSString*)UTIForFile:(NSString*)file {
	FSRef ref;
	if(FSPathMakeRef((const uint8_t*)[file fileSystemRepresentation], &ref, false) != noErr) return nil;
	NSDictionary *values;
	if(LSCopyItemAttributes(&ref, kLSRolesViewer, (CFArrayRef)[NSArray arrayWithObject:(id)kLSItemContentType], (CFDictionaryRef*)&values) != noErr) return nil;
	NSMakeCollectable(values);
	return [values objectForKey:(id)kLSItemContentType];
}


- (void)handleRequest:(WARequest *)req response:(WAResponse *)resp {
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
	NSDate *modificationDate = [attributes fileModificationDate];
		
	BOOL notModified = req.conditionalModificationDate && [req.conditionalModificationDate timeIntervalSinceDate:modificationDate] >= 0;
	
	if(notModified && enableCaching) {
		resp.statusCode = 304;
		[resp finish];
		return;
	}
	
	NSString *UTI = [[self class] UTIForFile:file];
	NSString *mediaType = NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef)UTI, kUTTagClassMIMEType));
	
	if(enableCaching) resp.modificationDate = modificationDate;
	resp.mediaType = mediaType;
	[resp appendBodyData:[NSData dataWithContentsOfFile:file]];
	[resp finish];
}

@end
