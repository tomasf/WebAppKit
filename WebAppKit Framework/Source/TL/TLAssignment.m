//
//  TLAssignment.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-15.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLAssignment.h"
#import "TLExpression.h"
#import "TLScope.h"

@implementation TLAssignment

- (id)initWithIdentifier:(NSString*)lhs value:(TLExpression*)rhs {
	self = [super init];
	identifier = [lhs copy];
	value = rhs;
	return self;
}

- (void)invokeInScope:(TLScope *)scope {
	[scope setValue:[value evaluateWithScope:scope] forKey:identifier];
}

@end
