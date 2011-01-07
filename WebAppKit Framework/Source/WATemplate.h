//
//  WSTemplate.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-16.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WAModule, WALocalization;


@interface WATemplate : NSObject {
	NSString *source;
	NSMutableDictionary *values;
	NSMutableSet *moduleIdentifiers;
	WALocalization *localization;
	WATemplate *layout;
}

@property(readonly) NSString *result;
@property(retain) WALocalization *localization;
@property(retain) WATemplate *layout;

+ (id)templateNamed:(NSString*)name;
- (id)initWithContentsOfURL:(NSURL*)URL;
- (id)initWithSource:(NSString*)templateString;

- (void)setValue:(id)value forKey:(NSString*)key;
- (id)valueForKey:(NSString*)key;

- (void)appendString:(NSString*)string toValueForKey:(NSString*)key;

- (void)addModule:(NSString*)identifier;
- (void)removeModule:(NSString*)identifier;

+ (void)setDefaultLocalization:(WALocalization*)loc;
+ (WALocalization*)defaultLocalization;
@end