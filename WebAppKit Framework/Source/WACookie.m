//
//  FTCookie.m
//  ForasteroTest
//
//  Created by Tomas Franzén on 2009-10-14.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import "WACookie.h"


@implementation WACookie


- (id)initWithName:(NSString*)cookieName value:(NSString*)cookieValue expirationDate:(NSDate*)date path:(NSString*)p domain:(NSString*)d {
	if(!(self = [super init])) return nil;
	
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
	return [NSString stringWithFormat:@"<%@ %p: %@=%@>", [self class], self, self.name, self.value];
}


- (id)copyWithZone:(NSZone *)zone {
	WACookie *copy = [[WACookie alloc] initWithName:self.name value:self.value expirationDate:self.expirationDate path:self.path domain:self.domain];
	copy.secure = self.secure;
	return copy;
}


- (NSString*)headerFieldValue {
	NSMutableString *baseValue = [NSMutableString stringWithFormat:@"%@=%@", WAConstructHTTPStringValue(self.name), WAConstructHTTPStringValue(self.value)];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@"1" forKey:@"Version"];
	
	if(self.expirationDate) {
		[params setObject:[NSString stringWithFormat:@"%qu", (uint64_t)[self.expirationDate timeIntervalSinceNow]] forKey:@"Max-Age"];
		// Compatibility with the old Netscape spec
		[params setObject:[[[self class] expiryDateFormatter] stringFromDate:self.expirationDate] forKey:@"Expires"];
	}
	
	if(self.path) [params setObject:self.path forKey:@"Path"];	
	if(self.domain) [params setObject:self.domain forKey:@"Domain"];
	if(self.secure) [params setObject:[NSNull null] forKey:@"Secure"];
	
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