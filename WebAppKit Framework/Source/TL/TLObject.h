//
//  TLObjectExpression.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLExpression.h"

@interface TLObject : TLExpression {
	id object;
}

- (id)initWithObject:(id)obj;

+ (TLExpression*)trueValue;
+ (TLExpression*)falseValue;
+ (TLExpression*)nilValue;
@end