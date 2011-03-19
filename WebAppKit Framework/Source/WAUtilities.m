//
//  WSUtilities.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-18.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAUtilities.h"
#include <mach/mach.h>
#include <mach/mach_time.h>


NSString *WAGenerateUUIDString(void) {
	return NSMakeCollectable(CFUUIDCreateString(NULL, CFMakeCollectable(CFUUIDCreate(NULL))));
}


// Recommended by Apple Technical Q&A 1398
uint64_t WANanosecondTime() {
	uint64_t time = mach_absolute_time();
	Nanoseconds nanosecs = AbsoluteToNanoseconds(*(AbsoluteTime *) &time);
	return *(uint64_t*)&nanosecs;	
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


NSString *WAExtractHeaderValueParameters(NSString *fullValue, NSDictionary **outParams) {
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	if(outParams) *outParams = params;
	
	NSInteger split = [fullValue rangeOfString:@";"].location;
	if(split == NSNotFound) return fullValue;
	NSString *basePart = [fullValue substringToIndex:split];
	NSString *parameterPart = [fullValue substringFromIndex:split];
	
	NSScanner *scanner = [NSScanner scannerWithString:parameterPart];
	for(;;) {
		if(![scanner scanString:@";" intoString:NULL]) break;		
		NSString *attribute = nil;
		if(![scanner scanUpToString:@"=" intoString:&attribute]) break;
		if(!attribute) break;
		[scanner scanString:@"=" intoString:NULL];
		if([scanner isAtEnd]) break;
		unichar c = [parameterPart characterAtIndex:[scanner scanLocation]];
		NSString *value = nil;
		if(c == '"') {
			[scanner scanString:@"\"" intoString:NULL];
			if(![scanner scanUpToString:@"\"" intoString:&value]) break;
			[scanner scanString:@"\"" intoString:NULL];
		}else{
			if(![scanner scanUpToString:@";" intoString:&value]) break;
		}
		
		[params setObject:value forKey:attribute];
	}
	return basePart;	
}