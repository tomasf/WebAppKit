//
//  Extras.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@interface NSDictionary (WAExtras)
- (NSDictionary*)dictionaryBySettingValue:(id)value forKey:(id)key;
@end

@interface NSString (WAExtras)
- (NSString*)HTMLEscapedString;
- (NSString*)HTML;
- (NSString*)hexMD5DigestUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)stringByEncodingBase64UsingEncoding:(NSStringEncoding)encoding;
- (NSString*)stringByDecodingBase64UsingEncoding:(NSStringEncoding)encoding;
- (NSString*)stringByEnforcingCharacterSet:(NSCharacterSet*)set;
@end

@interface NSArray (WAExtras)
- (NSArray*)filteredArrayUsingPredicateFormat:(NSString*)format, ...;
- (id)firstObjectMatchingPredicateFormat:(NSString*)format, ...;
- (id)sortedArrayUsingKeyPath:(NSString*)keyPath selector:(SEL)selector ascending:(BOOL)ascending;
@end

@interface NSData (WAExtras)
- (NSData*)MD5Digest;
- (NSString*)hexMD5Digest;
+ (NSData*)dataByDecodingBase64:(NSString*)string;
- (NSString*)base64String;
- (NSData*)dataByEncryptingAES128UsingKey:(NSData*)key;
- (NSData*)dataByDecryptingAES128UsingKey:(NSData*)key;
@end

@interface NSCharacterSet (WAExtras)
+ (id)characterSetWithRanges:(NSRange)firstRange, ...;
+ (NSCharacterSet*)ASCIIAlphanumericCharacterSet;
@end

@interface NSURL (WAExtras)
- (NSString*)realPath;
@end