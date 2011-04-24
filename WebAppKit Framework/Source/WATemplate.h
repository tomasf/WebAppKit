//
//  WATemplate.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class TLStatement;

@interface WATemplate : NSObject <NSCopying> {
	TLStatement *body;
	NSMutableDictionary *mapping;
}

+ (id)templateNamed:(NSString*)name;

- (id)initWithSource:(NSString*)templateString;
- (id)initWithContentsOfURL:(NSURL*)URL;


- (void)setValue:(id)value forKey:(NSString*)key;
- (id)valueForKey:(NSString*)key;

- (NSString*)result;
@end