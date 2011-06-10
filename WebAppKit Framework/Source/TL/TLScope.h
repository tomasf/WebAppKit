//
//  TLScope.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-11.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLScope : NSObject {
	TLScope *parent;
	NSMutableDictionary *mapping;
	NSDictionary *constants;
}

+ (void)defineConstant:(NSString*)name value:(id)value;
+ (void)undefineConstant:(NSString*)name;

- (id)initWithParentScope:(TLScope*)scope;
- (id)init;

- (id)valueForKey:(NSString*)key;
- (void)setValue:(id)value forKey:(NSString*)string;
- (void)declareValue:(id)value forKey:(NSString*)key;

- (NSString*)debugDescription;
@end