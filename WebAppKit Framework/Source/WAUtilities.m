//
//  WSUtilities.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-18.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAUtilities.h"

NSString *WAGenerateUUIDString(void) {
	return NSMakeCollectable(CFUUIDCreateString(NULL, CFMakeCollectable(CFUUIDCreate(NULL))));
}

NSString *WAApplicationSupportDirectory(void) {
	NSString *name = [[NSBundle mainBundle] bundleIdentifier];
	NSString *root = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString *directory = [root stringByAppendingPathComponent:name];
	if(![[NSFileManager defaultManager] fileExistsAtPath:directory])
		[[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:NULL];
	return directory;
}

NSDateFormatter *WAHTTPDateFormatter(void) {
	static NSDateFormatter *formatter;
	if(!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"E, dd MMM yyyy HH:mm:ss 'GMT'"];
		[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
		[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
	return formatter;
}