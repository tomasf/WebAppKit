//
//  TFStringScanner.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-04-12.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "TFStringScanner.h"

static BOOL CharacterIsWhitespace(unichar c) {
	return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}


@implementation TFStringScanner
@synthesize location, lastTokenType;

- (id)initWithString:(NSString*)string {
	self = [super init];
	content = [string copy];
	multicharSymbols = [NSMutableArray array];
	return self;
}

- (void)resortSymbols {
	[multicharSymbols sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"length" ascending:NO]]];	
}

- (void)addMulticharacterSymbol:(NSString*)symbol {
	[multicharSymbols addObject:symbol];
	[self resortSymbols];
}

- (void)addMulticharacterSymbols:(NSString*)symbol, ... {
	va_list list;
	va_start(list, symbol);
	do {
		[multicharSymbols addObject:symbol];
	} while(symbol = va_arg(list, NSString*));
	va_end(list);
	[self resortSymbols];
}

- (void)removeMulticharacterSymbol:(NSString*)symbol {
	[multicharSymbols removeObject:symbol];
	[self resortSymbols];
}


- (unichar)scanCharacter {
	if(self.atEnd) return 0;
	return [content characterAtIndex:location++];
}


- (NSString*)scanForLength:(NSUInteger)length {
	if(location + length > [content length]) return nil;
	NSString *sub = [content substringWithRange:NSMakeRange(location, length)];
	location += length;
	return sub;
}


- (BOOL)scanString:(NSString*)substring {
	NSUInteger length = [substring length];
	if(location + length > [content length]) return NO;
	
	NSString *sub = [content substringWithRange:NSMakeRange(location, length)];
	if([sub isEqual:substring]) {
		location += length;
		return YES;
	}else return NO;
}

- (NSString*)scanToString:(NSString*)substring {
	NSRange remainingRange = NSMakeRange(location, [content length]-location);
	NSUInteger newLocation = [content rangeOfString:substring options:0 range:remainingRange].location;
	if(newLocation == NSNotFound) {
		location = [content length];
		return [content substringWithRange:remainingRange];
	}
	NSString *string = [content substringWithRange:NSMakeRange(location, newLocation-location)];
	location = newLocation;
	return string;
}

- (NSString*)scanStringFromCharacterSet:(NSCharacterSet*)set {
	BOOL found = NO;
	NSUInteger start = location;
	while(!self.atEnd && [set characterIsMember:[content characterAtIndex:location]]) {
		location++;
		found = YES;
	}
	return found ? [content substringWithRange:NSMakeRange(start, location-start)] : nil;
}

- (BOOL)scanWhitespace {
	return [self scanStringFromCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] != nil;
}

- (NSString*)peekToken {
	NSUInteger loc = location;
	NSString *token = [self scanToken];
	location = loc;
	return token;
}

- (NSString*)scanToken {
	[self scanWhitespace];
	if(self.atEnd) return nil;
	
	static NSCharacterSet *digits;
	static NSMutableCharacterSet *alpha, *alphaNum, *symbols;
	
	if(!digits) {
		digits = [NSCharacterSet characterSetWithRange:NSMakeRange('0', 10)];
		alpha = [NSMutableCharacterSet characterSetWithRange:NSMakeRange('A', 26)];
		[alpha addCharactersInRange:NSMakeRange('a', 26)];
		[alpha addCharactersInString:@"_"];
		alphaNum = [alpha mutableCopy];
		[alphaNum formUnionWithCharacterSet:digits];
		symbols = [[alphaNum invertedSet] mutableCopy];
		[symbols removeCharactersInString:@" \t\r\n"];
	}
	
	unichar firstChar = [content characterAtIndex:location];
	if([alpha characterIsMember:firstChar]) {
		lastTokenType = TFTokenTypeIdentifier;
		return [self scanStringFromCharacterSet:alphaNum];
		
	}else if([digits characterIsMember:firstChar]) {
		lastTokenType = TFTokenTypeNumeric;
		return [self scanStringFromCharacterSet:digits];
	
	}else{
		lastTokenType = TFTokenTypeSymbol;
		for(NSString *symbol in multicharSymbols)
			if([self scanString:symbol]) return symbol;
		location++;
		return [NSString stringWithCharacters:&firstChar length:1];
	}
}


- (BOOL)atEnd {
	return location >= [content length];
}

- (NSString *)description {
	NSInteger radius = 15;
	NSUInteger start = MAX((NSInteger)self.location-radius, 0);
	NSUInteger end = MIN(self.location+radius, [content length]-1);
	NSString *sample = [content substringWithRange:NSMakeRange(start, end-start+1)];
	sample = [sample stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	sample = [sample stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
	NSString *pointString = [[@"" stringByPaddingToLength:self.location-start withString:@" " startingAtIndex:0] stringByAppendingString:@"^"];
	return [NSString stringWithFormat:@"<%@ %p at position %lu>\n%@\n%@", [self class], self, (unsigned long)self.location, sample, pointString];
}


@end
