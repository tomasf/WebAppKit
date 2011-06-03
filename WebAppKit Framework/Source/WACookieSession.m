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
#import <openssl/md5.h>

static const NSTimeInterval WASessionDefaultLifespan = 31556926;


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
	
	if([plaintext length] < MD5_DIGEST_LENGTH) {
		NSLog(@"Decoded cookie value too short.");
		return empty;
	}
	
	NSData *hash = [plaintext subdataWithRange:NSMakeRange(0, MD5_DIGEST_LENGTH)];
	NSData *payload = [plaintext subdataWithRange:NSMakeRange(MD5_DIGEST_LENGTH, [plaintext length]-MD5_DIGEST_LENGTH)];
	NSData *correctHash = [payload MD5Digest];
	
	if(![hash isEqualToData:correctHash]) {
		NSLog(@"Session cookie had invalid hash. Discarding data.");
		return empty;
	}
	
	NSDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:payload];
	if(!dictionary) {
		NSLog(@"Failed to unarchive plaintext cookie payload. Discarding data.");
		return empty;
	}
	return dictionary;
}


+ (NSString*)cookieValueFromDictionary:(NSDictionary*)dictionary key:(NSData*)key {
	NSData *payload = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
	if(!payload) [NSException raise:NSInternalInconsistencyException format:@"Session data archiving failed"];
	
	NSMutableData *data = [NSMutableData data];
	[data appendData:[payload MD5Digest]];
	[data appendData:payload];
	
	NSData *ciphertext = [data dataByEncryptingAES128UsingKey:key];
	if(!ciphertext) [NSException raise:NSInternalInconsistencyException format:@"Session data encryption failed"];	
						   
	NSString *base64 = [ciphertext base64String];
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
	NSString *value = [values count] ? [[self class] cookieValueFromDictionary:values key:encryptionKey] : @"";
	WACookie *cookie = [[WACookie alloc] initWithName:name value:value lifespan:WASessionDefaultLifespan path:nil domain:nil];
	[response addCookie:cookie];
}


- (void)setValue:(id)value forKey:(NSString*)key {
	[values setObject:value forKey:key];
	[self updateResponse];
}


- (id)valueForKey:(NSString*)key {
	return [values objectForKey:key];
}

- (void)removeValueForKey:(NSString*)key {
	[values removeObjectForKey:key];
	[self updateResponse];
}

@end
