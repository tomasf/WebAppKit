//
//  TLExpression.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-11.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TL.h"
#import "TFStringScanner.h"


@interface TLExpression ()
+ (TLExpression*)parseNumber:(TFStringScanner*)scanner;
+ (TLExpression*)parseInvocation:(TFStringScanner*)scanner;
+ (TLExpression*)parseExpression:(TFStringScanner*)scanner;
+ (TLExpression*)parseExpression:(TFStringScanner*)scanner endToken:(NSString*)string;
@end


@implementation TLExpression

- (id)evaluateWithScope:(TLScope*)scope {
	[NSException raise:NSInternalInconsistencyException format:@"%s needs to be overridden in %@", _cmd, [self class]];
	return nil;
}

- (id)evaluate {
	return [self evaluateWithScope:[[TLScope alloc] init]];
}


+ (TLExpression*)parseNumber:(TFStringScanner*)scanner {
	NSString *numberString = [scanner scanToken];
	if([numberString isEqual:@"-"])
		numberString = [numberString stringByAppendingString:[scanner scanToken]];
	
	if([[scanner peekToken] isEqual:@"."]) {
		[scanner scanToken];
		NSString *fraction = [scanner scanToken];
		unichar c = [fraction characterAtIndex:0];
		if(c >= '0' && c <= '9') {
			numberString = [numberString stringByAppendingFormat:@".%@", fraction];
		}else [NSException raise:TLParseException format:@"Expected number fraction after period, but found some other bullshit: %@", fraction];
	}
	return [[TLObject alloc] initWithObject:[NSNumber numberWithDouble:[numberString doubleValue]]];
}


+ (TLExpression*)parseInvocation:(TFStringScanner*)scanner {
	[scanner scanToken]; // [
	TLExpression *receiver = [self parseExpression:scanner];
	
	NSMutableString *selector = [NSMutableString string];
	NSMutableArray *arguments = [NSMutableArray array];
	
	for(;;) {
		NSString *part = [scanner scanToken];
		if([part isEqual:@"]"] && [arguments count]) break;
		
		if(scanner.lastTokenType != TFTokenTypeIdentifier)
			[NSException raise:TLParseException format:@"Expected method selector part, but found something bogus: %@", part];
		[selector appendString:part];
		
		NSString *sep = [scanner scanToken];
		if(![sep isEqual:@":"]) {
			if([sep isEqual:@"]"] && ![arguments count]) break;
			[NSException raise:TLParseException format:@"Expected method colon, but found this junk: %@", sep];
		}
		[selector appendString:@":"];
		
		TLExpression *arg = [self parseExpression:scanner];
		[arguments addObject:arg];
	}
	
	return [[TLMethodInvocation alloc] initWithReceiver:receiver selector:NSSelectorFromString(selector) arguments:arguments];
}


+ (TLExpression*)parseExpression:(TFStringScanner*)scanner {
	return [self parseExpression:scanner endToken:nil];
}


+ (TLExpression*)parseStringLiteral:(TFStringScanner*)scanner {
	[scanner scanToken]; // " or @"
	NSMutableString *string = [NSMutableString string];
	
	while(!scanner.atEnd) {
		unichar c = [scanner scanCharacter];
		if(c == '"') break;
		
		if(c == '\\') {
			switch([scanner scanCharacter]) {
				case '\\': c = '\\'; break;
				case '"': c = '"'; break;					
				case 'n': c = '\n'; break;
				case 'r': c = '\r'; break;
				case 't': c = '\t'; break;
				
				case 'x': {
					NSString *hex = [scanner scanForLength:2];
					unsigned value;
					if(!hex || ![[NSScanner scannerWithString:hex] scanHexInt:&value])
						[NSException raise:TLParseException format:@"Expected hex value following \\x, but found: %@", hex];
					c = (uint8_t)value;
					break;
				}
					
				case 'u': {
					NSString *hex = [scanner scanForLength:4];
					unsigned value;
					if(!hex || ![[NSScanner scannerWithString:hex] scanHexInt:&value])
						[NSException raise:TLParseException format:@"Expected hex value following \\u, but found: %@", hex];
					c = (unichar)value;
					break;
				}
			}
		}
		
		[string appendString:[NSString stringWithCharacters:&c length:1]];
	}
	
	return [[TLObject alloc] initWithObject:string];
}


+ (TLExpression*)parseExpression:(TFStringScanner*)scanner endToken:(NSString*)endToken {
	NSMutableArray *expressions = [NSMutableArray array];
	NSMutableArray *infixOperators = [NSMutableArray array];
	
	for(;;) {
		// Collect prefix operators
		NSMutableArray *prefixTokens = [NSMutableArray array];
		NSString *token = nil;
		while(token = [scanner peekToken]) {
			if([token isEqual:@"!"]) {
				[prefixTokens addObject:token];
				[scanner scanToken];
			}else break;
		}
		
		// Read value
		token = [scanner peekToken];
		if(!token) break;
		
		unichar c = [token characterAtIndex:0];
		TFTokenType type = scanner.lastTokenType;
		TLExpression *part = nil;
		
		if([token isEqual:@"("]) {
			[scanner scanToken];
			part = [self parseExpression:scanner];
			[scanner scanToken]; // )
		}else if(type == TFTokenTypeNumeric || c == '-') {
			part = [self parseNumber:scanner];
		}else if(c == '[') {
			part = [self parseInvocation:scanner];
			
		}else if(type == TFTokenTypeIdentifier) {
			part = [[TLIdentifier alloc] initWithName:[scanner scanToken]];
			
		}else if([token isEqual:@"\""] || [token isEqual:@"@\""]) {
			part = [self parseStringLiteral:scanner];
			
		}else{
			[NSException raise:TLParseException format:@"Expected expression, but found: %@", token];
		}

		
		// Scan for property keys (dot syntax)
		if([scanner scanString:@"."]) {
			NSMutableString *keyPath = [NSMutableString string];
			
			do {
				if([keyPath length]) [keyPath appendString:@"."];
				if([scanner scanString:@"@"]) [keyPath appendString:@"@"];
				NSString *string = [scanner scanToken];
				if(scanner.lastTokenType != TFTokenTypeIdentifier)
					[NSException raise:TLParseException format:@"Expected key name after period, but found this: %@", string];
				[keyPath appendString:string];
				
			}while([scanner scanString:@"."]);
			
			part = [[TLOperation alloc] initWithOperator:TLOperatorKeyPathSelection leftOperand:part rightOperand:[[TLObject alloc] initWithObject:keyPath]];
		}
		
		
		// Apply prefix operators
		for(NSString *token in [prefixTokens reverseObjectEnumerator]) {
			TLOperator op;
			if([token isEqual:@"!"]) op = TLOperatorNegation;
			part = [[TLOperation alloc] initWithOperator:op leftOperand:part rightOperand:nil];
		}
		
		[expressions addObject:part];
		

		// Operator part
		token = [scanner peekToken];
		c = [token characterAtIndex:0];
		type = scanner.lastTokenType;
		
		TLOperator operator = [TLOperation operatorForSymbol:token];
		
		if([endToken isEqual:token]) {
			break;
		}else if(operator) {
			[scanner scanToken];
			[infixOperators addObject:[NSNumber numberWithInt:operator]];
		
		}else break;
	}
	
	
	NSAssert([expressions count] == [infixOperators count]+1, @"Mayhem! The number of expressions must always be one more than the number of operators.");
	
	
	// Boil it all down
	while([infixOperators count]) {
		NSUInteger opIndex = [TLOperation indexOfPrecedingOperatorInArray:infixOperators];
		TLOperator op = [[infixOperators objectAtIndex:opIndex] intValue];
		TLOperation *operation = [[TLOperation alloc] initWithOperator:op leftOperand:[expressions objectAtIndex:opIndex] rightOperand:[expressions objectAtIndex:opIndex+1]];
		[expressions replaceObjectAtIndex:opIndex withObject:operation];
		[expressions removeObjectAtIndex:opIndex+1];
		[infixOperators removeObjectAtIndex:opIndex];
	}
	
	return [expressions objectAtIndex:0];
}


+ (TFStringScanner*)newScannerForString:(NSString*)string {
	TFStringScanner *scanner = [[TFStringScanner alloc] initWithString:string];
	[scanner addMulticharacterSymbols:@"==", @"!=", @"===", @"!==", @"<=", @">=", @"&&", @"||", @"@\"", nil];
	return scanner;
}


+ (TLExpression*)expressionByParsingString:(NSString*)string {
	TFStringScanner *scanner = [self newScannerForString:string];
	return [TLExpression parseExpression:scanner];
}


@end