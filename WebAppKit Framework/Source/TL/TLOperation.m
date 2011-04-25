//
//  TLOperation.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TL.h"


typedef struct {
	TLOperator operator;
	NSString *symbol;
	NSUInteger precedence;
} TLOperatorInfo;


static TLOperatorInfo operatorInfo[] = {
	{TLOperatorKeyPathSelection, nil, 0},
	{TLOperatorNegation, nil, 0},
	
	{TLOperatorMultiplication, @"*", 1},
	{TLOperatorDivision, @"/", 1},
	{TLOperatorAddition, @"+", 2},
	{TLOperatorSubtraction, @"-", 2},
	
	{TLOperatorLessThan, @"<", 3},
	{TLOperatorLessThanOrEqual, @"<=", 3},
	{TLOperatorGreaterThan, @">", 4},
	{TLOperatorGreaterThanOrEqual, @">=", 4},
	
	{TLOperatorIdentityEquality, @"===", 5},
	{TLOperatorIdentityInequality, @"!==", 5},
	
	{TLOperatorEquality, @"==", 6},
	{TLOperatorInequality, @"!=", 6},

	{TLOperatorAND, @"&&", 7},
	{TLOperatorOR, @"||", 8},
};

static NSUInteger operatorCount = sizeof(operatorInfo)/sizeof(operatorInfo[0]);




@implementation NSNumber (TLOperationExtras)

- (id)TL_add:(id)rhs {
	return [NSNumber numberWithDouble:[self doubleValue] + [rhs doubleValue]];
}

- (id)TL_subtract:(id)rhs {
	return [NSNumber numberWithDouble:[self doubleValue] - [rhs doubleValue]];
}

- (id)TL_multiply:(id)rhs {
	return [NSNumber numberWithDouble:[self doubleValue] * [rhs doubleValue]];
}

- (id)TL_divide:(id)rhs {
	return [NSNumber numberWithDouble:[self doubleValue] / [rhs doubleValue]];
}

@end





@implementation TLOperation

+ (TLOperator)operatorForSymbol:(NSString*)string {
	for(int i=0; i<operatorCount; i++) {
		if([operatorInfo[i].symbol isEqual:string])
			return operatorInfo[i].operator;
	}
	return TLOperatorInvalid;
}

+ (NSString*)symbolForOperator:(TLOperator)op {
	for(int i=0; i<operatorCount; i++) {
		if(operatorInfo[i].operator == op)
			return operatorInfo[i].symbol;
	}
	return nil;
}

+ (NSInteger)precedenceOfOperator:(TLOperator)op {
	for(int i=0; i<operatorCount; i++) {
		if(operatorInfo[i].operator == op)
			return operatorInfo[i].precedence;
	}
	return -1;
}

+ (NSUInteger)indexOfPrecedingOperatorInArray:(NSArray*)array {
	NSUInteger minPrec = NSUIntegerMax;
	NSUInteger minIndex = 0;
	NSUInteger i = 0;
	for(NSNumber *number in array) {
		TLOperator op = [number intValue];
		NSInteger prec = [self precedenceOfOperator:op];
		if(prec < minPrec) {
			minPrec = prec;
			minIndex = i;
		}
		i++;
	}
	return minIndex;
}


- (id)initWithOperator:(TLOperator)op leftOperand:(TLExpression*)left rightOperand:(TLExpression*)right {
	self = [super init];
	operator = op;
	leftOperand = left;
	rightOperand = right;
	
	if(leftOperand.constant && rightOperand.constant)
		return [[TLObject alloc] initWithObject:[self evaluateWithScope:nil]];
	
	return self;
}



- (BOOL)boolValueForComparison:(TLOperator)op object:(id)lhs object2:(id)rhs {
	NSComparisonResult result = [lhs compare:rhs];
	switch(op) {
		case TLOperatorLessThan: return result == NSOrderedAscending;
		case TLOperatorGreaterThan: return result == NSOrderedDescending;
		case TLOperatorLessThanOrEqual: return result != NSOrderedDescending;
		case TLOperatorGreaterThanOrEqual: return result != NSOrderedAscending;
		default: return NO;
	}
}


- (id)objectByApplyingOperator:(TLOperator)op object:(id)lhs object2:(id)rhs {
	BOOL boolValue = NO;
	
	switch(op) {
		case TLOperatorInvalid: [NSException raise:TLRuntimeException format:@"Invalid operator"];
		case TLOperatorKeyPathSelection: return [lhs valueForKeyPath:rhs];
		
		case TLOperatorAddition: return [lhs TL_add:rhs];
		case TLOperatorSubtraction: return [lhs TL_subtract:rhs];
		case TLOperatorMultiplication: return [lhs TL_multiply:rhs];
		case TLOperatorDivision: return [lhs TL_divide:rhs];
		
		case TLOperatorEquality: boolValue = [lhs isEqual:rhs]; break;
		case TLOperatorInequality: boolValue = ![lhs isEqual:rhs]; break;
		case TLOperatorIdentityEquality: boolValue = lhs == rhs; break;
		case TLOperatorIdentityInequality: boolValue = lhs != rhs; break;
			
		case TLOperatorNegation: boolValue = ![lhs boolValue]; break;
		case TLOperatorAND: boolValue = [lhs boolValue] && [rhs boolValue]; break;
		case TLOperatorOR: boolValue = [lhs boolValue] || [rhs boolValue]; break;
			
		case TLOperatorLessThan:
		case TLOperatorGreaterThan:
		case TLOperatorLessThanOrEqual:
		case TLOperatorGreaterThanOrEqual:
			boolValue = [self boolValueForComparison:op object:lhs object2:rhs];
			break;
	}
	
	return [NSNumber numberWithBool:boolValue];	
}


- (id)evaluateWithScope:(TLScope *)scope {
	id leftValue = [leftOperand evaluateWithScope:scope];
	id rightValue = [rightOperand evaluateWithScope:scope];
	
	return [self objectByApplyingOperator:operator object:leftValue object2:rightValue];
}


- (NSString*)description {
	return [NSString stringWithFormat:@"<Operation %d %@ %@>", operator, leftOperand, rightOperand];
}

@end