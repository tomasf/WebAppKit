//
//  Extras.h
//  WebServer
//
//  Created by Tomas Franzén on 2010-12-08.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

@interface NSDictionary (WAExtras)
+ (id)dictionaryWithKeysAndObjects:(id)firstKey, ...;
- (NSDictionary*)dictionaryBySettingValue:(id)value forKey:(id)key;
@end

@interface NSString (WAExtras)
- (NSString*)HTMLEscapedString;
- (NSString*)html;
- (NSString*)hexMD5DigestUsingEncoding:(NSStringEncoding)encoding;
- (NSString*)stringByEncodingBase64UsingEncoding:(NSStringEncoding)encoding;
- (NSString*)stringByDecodingBase64UsingEncoding:(NSStringEncoding)encoding;
@end

@interface NSArray (WAExtras)
- (NSArray*)filteredArrayUsingPredicateFormat:(NSString*)format, ...;
- (id)firstObjectMatchingPredicateFormat:(NSString*)format, ...;
@end

@interface NSData (WAExtras)
- (NSData*)MD5Digest;
- (NSString*)hexMD5Digest;
+ (NSData*)dataByDecodingBase64:(NSString*)string;
- (NSString*)base64String;
@end

#define $array(...) [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define $dict(...) [NSDictionary dictionaryWithKeysAndObjects:__VA_ARGS__, nil]
#define $marray(...) [NSMutableArray arrayWithObjects:__VA_ARGS__, nil]
#define $mdict(...) [NSMutableDictionary dictionaryWithKeysAndObjects:__VA_ARGS__, nil]