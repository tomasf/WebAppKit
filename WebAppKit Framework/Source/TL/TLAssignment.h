//
//  TLAssignment.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-15.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLStatement.h"
@class TLExpression;

@interface TLAssignment : TLStatement {
	NSString *identifier;
	TLExpression *value;
}

- (id)initWithIdentifier:(NSString*)lhs value:(TLExpression*)rhs;
@end
