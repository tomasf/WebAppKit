//
//  TLSymbol.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLIdentifier.h"
#import "TLScope.h"

@implementation TLIdentifier

- (id)initWithName:(NSString*)symbolName {
	self = [super init];
	name = [symbolName copy];
	return self;
}

- (id)evaluateWithScope:(TLScope *)scope {
	return [scope valueForKey:name];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Symbol %@>", name];
}

@end