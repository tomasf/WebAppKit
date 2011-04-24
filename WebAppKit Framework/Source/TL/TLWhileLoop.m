//
//  TLWhileLoop.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-17.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLWhileLoop.h"


@implementation TLWhileLoop

- (id)initWithCondition:(TLExpression*)expr body:(TLStatement*)bodyStatement {
	self = [super init];
	condition = expr;
	body = bodyStatement;
	return self;
}

- (void)invokeInScope:(TLScope *)scope {
	while([[condition evaluateWithScope:scope] boolValue])
		[body invokeInScope:scope];
}

@end
