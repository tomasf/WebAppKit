//
//  Extras.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAFoundationExtras.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>


@implementation NSDictionary (WAExtras)

- (NSDictionary*)dictionaryBySettingValue:(id)value forKey:(id)key {
	NSMutableDictionary *dict = [self mutableCopy];
	[dict setObject:value forKey:key];
	return dict;
}

@end


@implementation NSString (WAExtras)

- (NSString*)HTMLEscapedString {
	NSString *newString = self;
	newString = [newString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	newString = [newString stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	newString = [newString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	newString = [newString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	return newString;
}


- (NSString*)HTML {
	return [self HTMLEscapedString];
}


- (NSString*)URIEscape {
	return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
}


- (NSString*)hexMD5DigestUsingEncoding:(NSStringEncoding)encoding {
	return [[self dataUsingEncoding:encoding] hexMD5Digest];
}


- (NSString*)stringByEncodingBase64UsingEncoding:(NSStringEncoding)encoding {
	return [[self dataUsingEncoding:encoding] base64String];
}


- (NSString*)stringByDecodingBase64UsingEncoding:(NSStringEncoding)encoding {
	NSData *data = [NSData dataByDecodingBase64:self];
	return [[NSString alloc] initWithData:data encoding:encoding];
}


- (NSString*)stringByEnforcingCharacterSet:(NSCharacterSet*)set {
	NSMutableString *string = [NSMutableString string];
	for(int i=0; i<[self length]; i++) {
		unichar c = [self characterAtIndex:i];
		if([set characterIsMember:c]) [string appendFormat:@"%C", c];
	}
	return string;
}

@end



@implementation NSArray (WAExtras)

- (NSArray*)filteredArrayUsingPredicateFormat:(NSString*)format, ... {
	va_list list;
	va_start(list, format);
	NSPredicate *p = [NSPredicate predicateWithFormat:format arguments:list];
	va_end(list);
	return [self filteredArrayUsingPredicate:p];
}


- (id)firstObjectMatchingPredicateFormat:(NSString*)format, ... {
	va_list list;
	va_start(list, format);
	NSPredicate *p = [NSPredicate predicateWithFormat:format arguments:list];
	va_end(list);
	NSArray *array = [self filteredArrayUsingPredicate:p];
	return [array count] ? [array objectAtIndex:0] : nil;
}


- (id)sortedArrayUsingKeyPath:(NSString*)keyPath selector:(SEL)selector ascending:(BOOL)ascending {
	NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:keyPath ascending:ascending selector:selector];
	return [self sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
}

@end



@implementation NSData (WAExtras)

- (NSString*)hexMD5Digest {
	NSData *digest = [self MD5Digest];
	NSMutableString *hexDigest = [NSMutableString string];
	for(int i=0; i<[digest length]; i++)
		[hexDigest appendFormat:@"%02x", ((uint8_t*)[digest bytes])[i]];
	return hexDigest;	
}


- (NSData*)MD5Digest {
	NSMutableData *digest = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
	CC_MD5([self bytes], [self length], [digest mutableBytes]);
	return digest;
}


+ (NSData*)dataByDecodingBase64:(NSString*)string {
	NSData *encodedData = [string dataUsingEncoding:NSASCIIStringEncoding];
	SecTransformRef transform = SecDecodeTransformCreate(kSecBase64Encoding, NULL);
	SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFTypeRef)encodedData, NULL);
	NSData *output = (__bridge_transfer NSData*)SecTransformExecute(transform, NULL);
	CFRelease(transform);
	return output;
}


- (NSString*)base64String {
	SecTransformRef transform = SecEncodeTransformCreate(kSecBase64Encoding, NULL);
	SecTransformSetAttribute(transform, kSecTransformInputAttributeName, (__bridge CFTypeRef)self, NULL);
	NSData *output = (__bridge_transfer NSData*)SecTransformExecute(transform, NULL);
	CFRelease(transform);
	return [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
}


- (NSData*)dataByEncryptingAES128UsingKey:(NSData*)key {
	size_t outSize = 0;
	CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, [key bytes], [key length], NULL, [self bytes], [self length], NULL, 0, &outSize);
	
	NSMutableData *ciphertext = [NSMutableData dataWithLength:outSize];
	if(CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, [key bytes], [key length], NULL, [self bytes], [self length], [ciphertext mutableBytes], outSize, &outSize) != kCCSuccess)
		return nil;
	return ciphertext;
}


- (NSData*)dataByDecryptingAES128UsingKey:(NSData*)key {
	size_t outSize = 0;
	CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, [key bytes], [key length], NULL, [self bytes], [self length], NULL, 0, &outSize);
	
	NSMutableData *cleartext = [NSMutableData dataWithLength:outSize];
	if(CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, [key bytes], [key length], NULL, [self bytes], [self length], [cleartext mutableBytes], outSize, &outSize) != kCCSuccess)
		return nil;
	[cleartext setLength:outSize]; // Can be smaller due to padding
	return cleartext;
}


@end



@implementation NSCharacterSet (WAExtras)

+ (id)characterSetWithRanges:(NSRange)firstRange, ... {
	NSMutableCharacterSet *set = [NSMutableCharacterSet characterSetWithRange:firstRange];
	va_list list;
	va_start(list, firstRange);
	NSRange range;
	while((range = va_arg(list, NSRange)).length)
		[set addCharactersInRange:range];
	va_end(list);
	return set;
}


+ (NSCharacterSet*)ASCIIAlphanumericCharacterSet {
	static NSCharacterSet *set;
	if(!set) set = [NSCharacterSet characterSetWithRanges:NSMakeRange('a',26), NSMakeRange('A',26), NSMakeRange('0',10), NSMakeRange(0,0)];
	return set;
}

@end



@implementation NSURL (WAExtras)

// Avoids NSURL's stupid behavior of stripping trailing slashes in -path
- (NSString*)realPath {
	return (__bridge_transfer NSString*)CFURLCopyPath((__bridge CFURLRef)self);	
}

@end