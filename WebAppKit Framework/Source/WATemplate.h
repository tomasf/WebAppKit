//
//  WATemplate.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class TLStatement, WASession;

@interface WATemplate : NSObject <NSCopying> {
	TLStatement *body;
	NSMutableDictionary *mapping;
	WATemplate *parent;
	WASession *session;
}

@property(retain) WATemplate *parent;
@property(retain) WASession *session;

+ (id)templateNamed:(NSString*)name;
+ (id)templateNamed:(NSString*)name parent:(NSString*)parentName;

- (id)initWithSource:(NSString*)templateString;
- (id)initWithContentsOfURL:(NSURL*)URL;


- (void)setValue:(id)value forKey:(NSString*)key;
- (id)valueForKey:(NSString*)key;

- (void)setObject:(id)value forKeyedSubscript:(id)key;
- (id)objectForKeyedSubscript:(id)key;

- (NSString*)result;
@end