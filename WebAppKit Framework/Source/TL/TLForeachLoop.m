//
//  TLForeachLoop.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLForeachLoop.h"
#import "TLScope.h"
#import "TLExpression.h"

@implementation TLForeachLoop

- (id)initWithCollection:(TLExpression*)object body:(TLStatement*)contents variableName:(NSString*)var {
	self = [super init];
	collection = object;
	variableName = [var copy];
	body = contents;
	return self;
}

- (void)invokeInScope:(TLScope*)scope {
	id concreteCollection = [collection evaluateWithScope:scope];
	for(id object in concreteCollection) {
		TLScope *innerScope = [[TLScope alloc] initWithParentScope:scope];
		[innerScope declareValue:object forKey:variableName];
		[body invokeInScope:innerScope];
	}
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Foreach %@ in %@: %@>", variableName, collection, body];
}

@end
