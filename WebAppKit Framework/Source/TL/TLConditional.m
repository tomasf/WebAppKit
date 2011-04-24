//
//  TLConditionalExpression.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLConditional.h"
#import "TLExpression.h"

@implementation TLConditional

- (id)initWithConditions:(NSArray*)ifExpressions consequents:(NSArray*)thenStatements {
	self = [super init];
	NSAssert([ifExpressions count] == [thenStatements count], @"The number of conditions must match the number of consequents!");
	conditions = [ifExpressions copy];
	consequents = [thenStatements copy];
	return self;
}

- (void)invokeInScope:(TLScope *)scope {
	for(NSUInteger i=0; i<[conditions count]; i++) {
		TLExpression *condition = [conditions objectAtIndex:i];
		TLStatement *consequent = [consequents objectAtIndex:i];
		
		if([[condition evaluateWithScope:scope] boolValue]) {
			[consequent invokeInScope:scope];
			return;
		}
	}
}


- (NSString*)description {
	NSMutableString *desc = [NSMutableString stringWithString:@"<"];
	
	for(NSUInteger i=0; i<[conditions count]; i++) {
		TLExpression *condition = [conditions objectAtIndex:i];
		TLStatement *consequent = [consequents objectAtIndex:i];
	
		if(i) [desc appendFormat:@", Else if %@ then %@", condition, consequent];
		else [desc appendFormat:@"If %@ then %@", condition, consequent];
	}
	[desc appendString:@">"];
	return desc;
}

@end