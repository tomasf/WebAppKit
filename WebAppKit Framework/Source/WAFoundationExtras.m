//
//  Extras.m
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WAFoundationExtras.h"
#import <openssl/md5.h>
#import <openssl/bio.h>
#import <openssl/evp.h>
#import <CommonCrypto/CommonCryptor.h>

@implementation NSDictionary (WAExtras)

+ (id)dictionaryWithKeysAndObjects:(id)firstKey, ... {
	va_list list;
	va_start(list, firstKey);
	NSString *key = firstKey;
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	while(key) {
		NSString *value = va_arg(list, id);
		if(value)
			[dict setObject:value forKey:key];
		key = va_arg(list, id);
	}
	va_end(list);
	return dict;
}

- (NSDictionary*)dictionaryBySettingValue:(id)value forKey:(id)key {
	NSMutableDictionary *dict = [self mutableCopy];
	[dict setObject:value forKey:key];
	return dict;
}

@end


@implementation NSString (WAExtras)

- (NSString*)HTMLEscapedString {
	self = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	self = [self stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	self = [self stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	self = [self stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	return self;
}

- (NSString*)HTML {
	return [self HTMLEscapedString];
}

- (NSString*)URIEscape {
	return NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8));
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
	NSMutableData *digest = [NSMutableData dataWithLength:MD5_DIGEST_LENGTH];
	MD5([self bytes], [self length], [digest mutableBytes]);
	return digest;
}


+ (NSData*)dataByDecodingBase64:(NSString*)string {
    NSData *encodedData = [[string stringByAppendingString:@"\n"] dataUsingEncoding:NSASCIIStringEncoding];
    
    BIO *command = BIO_new(BIO_f_base64());
	BIO_set_flags(command, BIO_FLAGS_BASE64_NO_NL);
    BIO *context = BIO_new_mem_buf((void *)[encodedData bytes], [encodedData length]);
    context = BIO_push(command, context);
	
    // Encode all the data
    NSMutableData *outputData = [NSMutableData data];
    
	int bufferSize = 256;
    int len;
    char inbuf[bufferSize];
    while(len = BIO_read(context, inbuf, bufferSize))
		[outputData appendBytes:inbuf length:len];
	
    BIO_free_all(context);
	return outputData;
}


- (NSString*)base64String {
	// Tell a context to encode base64
	BIO *context = BIO_new(BIO_s_mem());
	BIO *command = BIO_new(BIO_f_base64());
	BIO_set_flags(command, BIO_FLAGS_BASE64_NO_NL);
	context = BIO_push(command, context);
	
	// Encode data
	BIO_write(context, [self bytes], [self length]);
	BIO_flush(context);
	
	// Get the resulting data
	char *outputBuffer;
	long outputLength = BIO_get_mem_data(context, &outputBuffer);	
	NSString *encodedString = [[[NSString alloc] initWithBytes:outputBuffer length:outputLength encoding:NSASCIIStringEncoding] autorelease];
	BIO_free_all(context);
	return encodedString;
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