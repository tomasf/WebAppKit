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

static NSMutableDictionary *extensionMediaTypeMapping;


@interface WAStaticFileHandler ()
@property(copy) NSString *file;
@property BOOL enableCaching;
@end



@implementation WAStaticFileHandler

+ (NSString*)mediaTypeForFileExtension:(NSString*)extension {
	if(!extensionMediaTypeMapping) {
		NSURL *mappingFileURL = [[NSBundle bundleForClass:[WAStaticFileHandler class]] URLForResource:@"MediaTypes" withExtension:@"plist"];
		extensionMediaTypeMapping = [NSMutableDictionary dictionaryWithContentsOfURL:mappingFileURL];
	}
	
	return [extensionMediaTypeMapping objectForKey:extension];
}


+ (void)setMediaType:(NSString*)mediaType forFileExtension:(NSString*)extension {
	[extensionMediaTypeMapping setObject:mediaType forKey:extension];
}


- (id)initWithFile:(NSString*)path enableCaching:(BOOL)useHTTPCache {
	if(!(self = [super init])) return nil;
	
	self.file = path;
	self.enableCaching = useHTTPCache;
	self.statusCode = 200;
	
	return self;
}


// We use this instead of -[NSWorkspace typeOfFile:error:] because NSWorkspace is in AppKit.
+ (NSString*)UTIForFile:(NSString*)file {
	FSRef ref;
	if(FSPathMakeRef((const uint8_t*)[file fileSystemRepresentation], &ref, false) != noErr) return nil;
	CFDictionaryRef values = nil;
	if(LSCopyItemAttributes(&ref, kLSRolesViewer, (__bridge CFArrayRef)[NSArray arrayWithObject:(__bridge id)kLSItemContentType], &values) != noErr) return nil;
	
	NSString *type = (__bridge NSString*)CFDictionaryGetValue(values, kLSItemContentType);
	if(values) CFRelease(values);
	return type;
}


+ (NSString*)mediaTypeForFile:(NSString*)file {
	NSString *extension = [file pathExtension];
	if(extension) {
		NSString *mediaType = [[self class] mediaTypeForFileExtension:extension];
		if(mediaType) return mediaType;
	}
	
	NSString *defaultType = @"application/octet-stream";
	NSString *UTI = [self UTIForFile:file];
	if(!UTI) return defaultType;
	NSString *mediaType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
	if(!mediaType) return defaultType;
	return mediaType;
}


- (void)handleRequest:(WARequest *)req response:(WAResponse *)resp {
	resp.statusCode = self.statusCode;
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.file error:NULL];
	NSDate *modificationDate = [attributes fileModificationDate];
		
	BOOL notModified = req.conditionalModificationDate && [req.conditionalModificationDate timeIntervalSinceDate:modificationDate] >= 0;
	
	if(notModified && self.enableCaching) {
		resp.statusCode = 304;
		resp.hasBody = NO;
		[resp finish];
		return;
	}
	
	resp.mediaType = [[self class] mediaTypeForFile:self.file];
	if(self.enableCaching) resp.modificationDate = modificationDate;
	
	[resp appendBodyData:[NSData dataWithContentsOfFile:self.file]];
	[resp finish];
}


@end