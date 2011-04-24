//
//  TLOperation.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLExpression.h"

typedef enum {
	TLOperatorInvalid = 0,
	
	// Suffix
	TLOperatorKeyPathSelection,
	
	// Prefix
	TLOperatorNegation,
	
	// Infix
	TLOperatorAddition,
	TLOperatorSubtraction,
	TLOperatorMultiplication,
	TLOperatorDivision,
	
	TLOperatorEquality,
	TLOperatorInequality,
	TLOperatorLessThan,
	TLOperatorGreaterThan,
	TLOperatorLessThanOrEqual,
	TLOperatorGreaterThanOrEqual,
	
	TLOperatorAND,
	TLOperatorOR,	
	
	TLOperatorIdentityEquality,
	TLOperatorIdentityInequality,
} TLOperator;


@interface TLOperation : TLExpression {
	TLOperator operator;
	TLExpression *leftOperand;
	TLExpression *rightOperand;
}

- (id)initWithOperator:(TLOperator)op leftOperand:(TLExpression*)left rightOperand:(TLExpression*)right;


+ (TLOperator)operatorForSymbol:(NSString*)string;
+ (NSUInteger)indexOfPrecedingOperatorInArray:(NSArray*)array;
@end