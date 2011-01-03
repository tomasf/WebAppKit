//
//  FTCookie.m
//  ForasteroTest
//
//  Created by Tomas Franzén on 2009-10-14.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import "WACookie.h"


@implementation WACookie
@synthesize name, value, path, domain, expirationDate;

+ (NSSet*)cookiesFromHeaderValue:(NSString*)headerValue {
	NSScanner *s = [NSScanner scannerWithString:headerValue];
	NSMutableSet *cookies = [NSMutableSet set];
	
	while(1) {
		NSString *name, *value;
		if(![s scanUpToString:@"=" intoString:&name]) break;
		if(![s scanString:@"=" intoString:NULL]) break;
		if(![s scanUpToString:@";" intoString:&value] && !value) break;
		[s scanString:@";" intoString:NULL];
		
		WACookie *c = [[[WACookie alloc] initWithName:name value:value expirationDate:nil path:nil domain:nil] autorelease];
		[cookies addObject:c];
	}
	return cookies;
}

- (id)initWithName:(NSString*)cookieName value:(NSString*)cookieValue expirationDate:(NSDate*)date path:(NSString*)p domain:(NSString*)d {
	[super init];
	NSParameterAssert(cookieName && cookieValue);
	self.name = cookieName;
	self.value = cookieValue;
	self.expirationDate = date;
	self.path = p;
	self.domain = d;
	return self;
}

- (id)initWithName:(NSString*)n value:(NSString*)val lifespan:(NSTimeInterval)time path:(NSString*)p domain:(NSString*)d {
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:time];
	return [self initWithName:n value:val expirationDate:date path:p domain:d];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<%@ %p: %@=%@>", [self class], self, name, value];
}

- (NSString*)headerFieldValue {
	NSMutableString *string = [NSMutableString stringWithFormat:@"%@=%@", name, value];
	
	if(expirationDate) {
		NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease];
		[f setDateFormat:@"EEE, dd-MMM-y HH:mm:ss 'GMT'"];
		[f setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		[f setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
		[string appendFormat:@"; expires=%@", [f stringFromDate:expirationDate]];
	}
	
	if(path)
		[string appendFormat:@"; path=%@", path];
	
	if(domain)
		[string appendFormat:@"; domain=%@",domain];
	
	return string;
}

@end
