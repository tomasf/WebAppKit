//
//  TLCompoundExpression.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLCompoundStatement.h"
#import "TLScope.h"

@implementation TLCompoundStatement

- (id)initWithStatements:(NSArray*)array {
	self = [super init];
	statements = [array copy];
	return self;
}

- (void)invokeInScope:(TLScope *)scope {
	TLScope *innerScope = [[TLScope alloc] initWithParentScope:scope];
	for(TLStatement *statement in statements)
		[statement invokeInScope:innerScope];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"<Compound: %@>", statements];
}

@end