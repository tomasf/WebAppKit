//
//  WACookieSession.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-04.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WACookieSession.h"
#import "WACookie.h"
#import "WARequest.h"
#import "WAResponse.h"

static const NSTimeInterval WSSessionDefaultLifespan = 31556926;


@implementation WACookieSession


+ (NSString*)tokenValueFromBase64:(NSString*)base64 {
	return [base64 stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
}

+ (NSString*)base64FromTokenValue:(NSString*)token {
	return [token stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
}


+ (NSDictionary*)dictionaryFromCookieValue:(NSString*)value key:(NSData*)key {
	NSDictionary *empty = [NSDictionary dictionary];
	if(!value) return empty;
	
	NSData *ciphertext = [NSData dataByDecodingBase64:[self base64FromTokenValue:value]];
	if(!ciphertext) {
		NSLog(@"Invalid base64 in cookie. Discarding data.");
		return empty;
	}
	NSData *plaintext = [ciphertext dataByDecryptingAES128UsingKey:key];
	if(!plaintext) {
		NSLog(@"Cookie value decryption failed. Discarding data.");
		return empty;
	}
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:plaintext];
	if(!dictionary) {
		NSLog(@"Failed to unarchive plaintext cookie payload. Discarding data.");
		return empty;
	}
	return dictionary;
}


+ (NSString*)cookieValueFromDictionary:(NSDictionary*)dictionary key:(NSData*)key {
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	if(!data) [NSException raise:NSInternalInconsistencyException format:@"Session data archiving failed"];
	data = [data dataByEncryptingAES128UsingKey:key];
	if(!data) [NSException raise:NSInternalInconsistencyException format:@"Session data encryption failed"];	
	NSString *base64 = [data base64String];
	if(!base64) [NSException raise:NSInternalInconsistencyException format:@"Session data base64 encoding failed"];	
	return [self tokenValueFromBase64:base64];
}


- (id)initWithName:(NSString*)n encryptionKey:(NSData*)key request:(WARequest*)req response:(WAResponse*)resp {
	self = [super init];
	name = [n copy];
	encryptionKey = [key copy];
	request = req;
	response = resp;
	
	NSUInteger keyLength = [encryptionKey length];
	if(keyLength != 16 && keyLength != 24 && keyLength != 32)
		[NSException raise:NSInvalidArgumentException format:@"AES encryption key must be 128, 192 or 256 bits long."];
	
	
	WACookie *cookie = [request cookieForName:name];
	values = [[[self class] dictionaryFromCookieValue:cookie.value key:encryptionKey] mutableCopy];
	
	return self;
}


- (void)updateResponse {
	NSString *value = [[self class] cookieValueFromDictionary:values key:encryptionKey];
	WACookie *cookie = [[WACookie alloc] initWithName:name value:value lifespan:WSSessionDefaultLifespan path:nil domain:nil];
	[response addCookie:cookie];
}


- (void)setValue:(id)value forKey:(NSString*)key {
	[values setObject:value forKey:key];
	[self updateResponse];
}


- (id)valueForKey:(NSString*)key {
	return [values objectForKey:key];
}

@end
