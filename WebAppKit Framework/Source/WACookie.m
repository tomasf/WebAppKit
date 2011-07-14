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


- (id)initWithName:(NSString*)n value:(NSString*)val {
	return [self initWithName:n value:val expirationDate:nil path:nil domain:nil];
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
	NSMutableString *baseValue = [NSMutableString stringWithFormat:@"%@=%@", WAConstructHTTPStringValue(name), WAConstructHTTPStringValue(value)];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@"1" forKey:@"Version"];
	
	if(expirationDate) {
		[params setObject:[NSString stringWithFormat:@"%qu", (uint64_t)[expirationDate timeIntervalSinceNow]] forKey:@"Max-Age"];
		// Compatibility with the old Netscape spec
		[params setObject:[[[self class] expiryDateFormatter] stringFromDate:expirationDate] forKey:@"Expires"];
	}
	
	if(path) [params setObject:path forKey:@"Path"];	
	if(domain) [params setObject:domain forKey:@"Domain"];
	if(secure) [params setObject:[NSNull null] forKey:@"Secure"];
	
	return [baseValue stringByAppendingString:WAConstructHTTPParameterString(params)];
}


// Old Netscape date format
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


+ (id)expiredCookieWithName:(NSString*)name {
	return [[self alloc] initWithName:name value:@"" lifespan:-10000 path:nil domain:nil];
}


@end