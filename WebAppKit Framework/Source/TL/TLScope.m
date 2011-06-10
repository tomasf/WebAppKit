//
//  TLScope.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-11.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TLScope.h"
#import "TLObject.h"
#import "TL.h"

static NSMutableDictionary *TLConstants;
static NSString *const TLNilPlaceholder = @"TLNilPlaceholder";


@implementation TLScope

+ (void)initialize {
	if(!TLConstants) TLConstants = [NSMutableDictionary dictionary];
	[self defineConstant:@"YES" value:[NSNumber numberWithBool:YES]];
	[self defineConstant:@"NO" value:[NSNumber numberWithBool:NO]];
}

+ (void)defineConstant:(NSString*)name value:(id)value {
	@synchronized(TLConstants) {
		[TLConstants setObject:value forKey:name];
	}
}

+ (void)undefineConstant:(NSString*)name {
	@synchronized(TLConstants) {
		[TLConstants removeObjectForKey:name];
	}
}

- (id)initWithParentScope:(TLScope *)scope {
	self = [super init];
	parent = scope;
	if(!scope) {
		@synchronized(TLConstants) {
			constants = [TLConstants copy];
		}
	}
	return self;
}

- (id)init {
	return [self initWithParentScope:nil];
}

- (id)rawValueForKey:(NSString*)key {
	id value = [mapping objectForKey:key];
	if(value) return value;	
	
	value = [constants valueForKey:key];
	if(value) return value;
	
	value = [parent rawValueForKey:key];
	if(value) return value;
	
	if([key isEqual:@"nil"] || [key isEqual:@"NULL"]) return nil;
	
	value = NSClassFromString(key);
	if(value) return value;
	
	[NSException raise:TLRuntimeException format:@"'%@' is undefined", key];
	return value;
}


- (id)valueForKey:(NSString*)key {
	id value = [self rawValueForKey:key];
	if(value == TLNilPlaceholder) return nil;
	return value;
}

- (BOOL)setValue:(id)value ifKeyExists:(NSString*)key {
	if(mapping && [mapping objectForKey:key]) {
		[mapping setObject:value forKey:key];
		return YES;
	} else return [parent setValue:value ifKeyExists:key];
}

- (void)setValue:(id)value forKey:(NSString*)key {
	if(!value) value = TLNilPlaceholder;
	
	if(![self setValue:value ifKeyExists:key]) {
		if(!mapping) mapping = [NSMutableDictionary dictionary];
		[mapping setObject:value forKey:key];
	}
}

- (void)declareValue:(id)value forKey:(NSString*)key {
	if(!value) value = TLNilPlaceholder;
	if(!mapping) mapping = [NSMutableDictionary dictionary];
	[mapping setObject:value forKey:key];
}

- (NSString*)stringByIndentingString:(NSString*)string {
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSMutableArray *newLines = [NSMutableArray array];
	for(NSString *line in lines) {
		[newLines addObject:[@"   " stringByAppendingString:line]];
	}
	return [newLines componentsJoinedByString:@"\n"];
}

- (NSString*)debugDescription {
	NSMutableString *output = [NSMutableString stringWithFormat:@"(\n"];
	for(id key in mapping) {
		if([key hasPrefix:@"_WATemplate"]) continue;
		[output appendFormat:@"\"%@\" = %@\n", key, [mapping valueForKey:key]];
	}
	if(parent) [output appendFormat:@"parent scope:\n%@\n", [self stringByIndentingString:[parent debugDescription]]];
	[output appendFormat:@")"];
	return output;
}

@end
