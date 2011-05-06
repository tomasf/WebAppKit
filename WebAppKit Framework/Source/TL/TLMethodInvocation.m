//
//  TLMethodInvocation.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-11.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TL.h"
#import <objc/runtime.h>
#import <objc/message.h>


NSUInteger TLArgumentCountForSelector(SEL selector) {
	return [[NSStringFromSelector(selector) componentsSeparatedByString:@":"] count]-1;
}


@implementation TLMethodInvocation

- (id)initWithReceiver:(TLExpression*)expr selector:(SEL)sel arguments:(NSArray*)args {
	self = [super init];
	target = expr;
	selector = sel;
	arguments = [args copy];
	
	NSUInteger argCount = TLArgumentCountForSelector(selector);
	if(argCount > 6)
		[NSException raise:NSInvalidArgumentException format:@"Too many arguments in %@", NSStringFromSelector(selector)];
	if(argCount != [arguments count])
		[NSException raise:NSInvalidArgumentException format:@"Selector '%@' does not match supplied argument count (%d).", NSStringFromSelector(selector), (int)[args count]];
	
	return self;
	
}


#define ARGTYPE(_ENCODE_TYPE_) (strcmp(type, @encode(_ENCODE_TYPE_)) == 0)

- (void)copyArgument:(id)object toType:(const char*)type buffer:(void*)buffer {
	if(ARGTYPE(id)) {
		*(id*)buffer = object;
		return;
	}

	
	NSNumber *n = (NSNumber*)object;
	
	if(ARGTYPE(char)) *(char*)buffer = [n charValue];
	else if(ARGTYPE(int)) *(int*)buffer = [n intValue];
	else if(ARGTYPE(short)) *(short*)buffer = [n shortValue];
	else if(ARGTYPE(long)) *(long*)buffer = [n longValue];
	else if(ARGTYPE(long long)) *(long long*)buffer = [n longLongValue];
	
	else if(ARGTYPE(unsigned char)) *(unsigned char*)buffer = [n unsignedCharValue];
	else if(ARGTYPE(unsigned int)) *(unsigned int*)buffer = [n unsignedIntValue];
	else if(ARGTYPE(unsigned short)) *(unsigned short*)buffer = [n unsignedShortValue];
	else if(ARGTYPE(unsigned long)) *(unsigned long*)buffer = [n unsignedLongValue];
	else if(ARGTYPE(unsigned long long)) *(unsigned long long*)buffer = [n unsignedLongLongValue];
	
	else if(ARGTYPE(float)) *(float*)buffer = [n floatValue];
	else if(ARGTYPE(double)) *(double*)buffer = [n doubleValue];
	
	else if([object isKindOfClass:[NSValue class]] && strcmp([object objCType], type) == 0) {
		[object getValue:buffer];
	}
	
	else [NSException raise:TLRuntimeException format:@"Can't coerce object of class %@ to type encoding %s", [object class], type];
}


- (id)objectFromReturnValue:(void*)buffer ofType:(const char*)type {
	if(ARGTYPE(id)) return *(id*)buffer;
	
	if(ARGTYPE(char)) return [NSNumber numberWithChar:*(char*)buffer];
	else if(ARGTYPE(int)) return [NSNumber numberWithInt:*(int*)buffer];
	else if(ARGTYPE(short)) return [NSNumber numberWithShort:*(short*)buffer];
	else if(ARGTYPE(long)) return [NSNumber numberWithLong:*(long*)buffer];
	else if(ARGTYPE(long long)) return [NSNumber numberWithLongLong:*(long long*)buffer];
	
	else if(ARGTYPE(unsigned char)) return [NSNumber numberWithUnsignedChar:*(unsigned char*)buffer];
	else if(ARGTYPE(unsigned int)) return [NSNumber numberWithUnsignedInt:*(unsigned int*)buffer];
	else if(ARGTYPE(unsigned short)) return [NSNumber numberWithUnsignedShort:*(unsigned short*)buffer];
	else if(ARGTYPE(unsigned long)) return [NSNumber numberWithUnsignedLong:*(unsigned long*)buffer];
	else if(ARGTYPE(unsigned long long)) return [NSNumber numberWithUnsignedLongLong:*(unsigned long long*)buffer];
	
	else if(ARGTYPE(float)) return [NSNumber numberWithFloat:*(float*)buffer];
	else if(ARGTYPE(double)) return [NSNumber numberWithDouble:*(double*)buffer];
	
	else return [NSValue valueWithBytes:buffer objCType:type];
}


- (id)evaluateWithScope:(TLScope *)scope {
	id object = [target evaluateWithScope:scope];
	if(!object) return nil;
	
	NSMethodSignature *signature = [object methodSignatureForSelector:selector];
	
	if([arguments count] == 0 && strcmp([signature methodReturnType], @encode(id)) == 0)
		return objc_msgSend(object, selector); // Fast path
	
	
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	
	uint8_t scratch[[signature frameLength]];
	NSUInteger index = 2; // skip self and _cmd
	for(TLExpression *expr in arguments) {
		id arg = [expr evaluateWithScope:scope];
		
		const char *type = [signature getArgumentTypeAtIndex:index];
		[self copyArgument:arg toType:type buffer:scratch];
		[invocation setArgument:scratch atIndex:index];
		
		index++;
	}
	
	[invocation setSelector:selector];
	[invocation invokeWithTarget:object];
	
	uint8_t value[[signature methodReturnLength]];
	[invocation getReturnValue:&value];
	return [self objectFromReturnValue:value ofType:[signature methodReturnType]];
}


- (NSString*)description {
	return [NSString stringWithFormat:@"<Method Invocation; target=%@, method=%@, args=%@>", target, NSStringFromSelector(selector), arguments];
}


@end