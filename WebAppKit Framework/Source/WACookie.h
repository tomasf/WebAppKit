//
//  FTCookie.h
//  ForasteroTest
//
//  Created by Tomas Franzén on 2009-10-14.
//  Copyright 2009 Lighthead Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WACookie : NSObject <NSCopying>
@property(copy) NSString *name;
@property(copy) NSString *value;
@property(copy) NSString *path;
@property(copy) NSString *domain;
@property(copy) NSDate *expirationDate;
@property BOOL secure;

@property(readonly) NSString *headerFieldValue;

- (id)initWithName:(NSString*)n value:(NSString*)val;
- (id)initWithName:(NSString*)n value:(NSString*)val expirationDate:(NSDate*)date path:(NSString*)p domain:(NSString*)d;
- (id)initWithName:(NSString*)n value:(NSString*)val lifespan:(NSTimeInterval)time path:(NSString*)p domain:(NSString*)d;

+ (id)expiredCookieWithName:(NSString*)name;

+ (NSSet*)cookiesFromHeaderValue:(NSString*)headerValue;
@end