//
//  TLWhileLoop.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-17.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TL.h"

@interface TLWhileLoop : TLStatement {
	TLExpression *condition;
	TLStatement *body;
}

- (id)initWithCondition:(TLExpression*)expr body:(TLStatement*)bodyStatement;
@end