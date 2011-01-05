//
//  FTCookie.m
//  ForasteroTest
//
//  Created by Tomas Franzén on 2009-10-14.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import "WACookie.h"

@interface WACookie ()
+ (NSDateFormatter*)expiryDateFormatter;
@end


@implementation WACookie
@synthesize name, value, path, domain, expirationDate, secure;


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


- (id)copyWithZone:(NSZone *)zone {
	WACookie *copy = [[WACookie alloc] initWithName:name value:value expirationDate:expirationDate path:path domain:domain];
	copy.secure = self.secure;
	return copy;
}


- (NSString*)headerFieldValue {
	NSMutableString *string = [NSMutableString stringWithFormat:@"%@=%@; Version=1", name, value];
	
	if(expirationDate) {
		[string appendFormat:@"; Max-Age=%qu", (uint64_t)[expirationDate timeIntervalSinceNow]];
		// Compatibility with the old Netscape spec
		[string appendFormat:@"; Expires=%@", [[[self class] expiryDateFormatter] stringFromDate:expirationDate]];
	}
	
	if(path)
		[string appendFormat:@"; Path=%@", path];
	
	if(domain)
		[string appendFormat:@"; Domain=%@",domain];
	
	if(secure)
		[string appendFormat:@"; Secure"];
	
	return string;
}


+ (NSDateFormatter*)expiryDateFormatter {
	static NSDateFormatter *formatter;
	if(!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEE, dd-MMM-y HH:mm:ss 'GMT'"];
		[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
		[formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	}
	return formatter;
}


+ (NSSet*)cookiesFromHeaderValue:(NSString*)headerValue {
	NSScanner *s = [NSScanner scannerWithString:headerValue];
	NSMutableSet *cookies = [NSMutableSet set];
	
	while(1) {
		NSString *name, *value;
		if(![s scanUpToString:@"=" intoString:&name]) break;
		if(![s scanString:@"=" intoString:NULL]) break;
		if(![s scanUpToString:@";" intoString:&value] && !value) break;
		[s scanString:@";" intoString:NULL];
		
		WACookie *c = [[WACookie alloc] initWithName:name value:value expirationDate:nil path:nil domain:nil];
		[cookies addObject:c];
	}
	return cookies;
}


@end