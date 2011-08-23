#import "TFStringScanner.h"

static NSCharacterSet *digitCharacters, *alphaCharacters, *alphanumericCharacters, *symbolCharacters;


@implementation TFStringScanner
@synthesize location, lastTokenType, string=content;


+ (void)initialize {
	digitCharacters = [[NSCharacterSet characterSetWithRange:NSMakeRange('0', 10)] retain];
	
	NSMutableCharacterSet *alpha = [NSMutableCharacterSet characterSetWithRange:NSMakeRange('a', 26)];
	[alpha addCharactersInRange:NSMakeRange('A', 26)];
	[alpha addCharactersInString:@"_"];
	alphaCharacters = [alpha retain];
	
	NSMutableCharacterSet *alphanum = [digitCharacters mutableCopy];
	[alphanum formUnionWithCharacterSet:alphaCharacters];
	alphanumericCharacters = alphanum;
	
	NSMutableCharacterSet *symbols = [[alphanumericCharacters invertedSet] mutableCopy];
	[symbols removeCharactersInString:@" \t\r\n"];
	symbolCharacters = symbols;
}


+ (id)scannerWithString:(NSString*)string {
	return [[[self alloc] initWithString:string] autorelease];	
}


- (id)initWithString:(NSString*)string {
	self = [super init];
	content = [string copy];
	multicharSymbols = [[NSMutableArray alloc] init];
	return self;
}


- (void)dealloc {
	[content release];
	[multicharSymbols release];
	[super dealloc];	
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
	} while((symbol = va_arg(list, NSString*)));
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
	
	unichar firstChar = [content characterAtIndex:location];
	
	if([alphaCharacters characterIsMember:firstChar]) {
		lastTokenType = TFTokenTypeIdentifier;
		return [self scanStringFromCharacterSet:alphanumericCharacters];
		
	}else if([digitCharacters characterIsMember:firstChar]) {
		lastTokenType = TFTokenTypeNumeric;
		return [self scanStringFromCharacterSet:digitCharacters];
	
	}else{
		lastTokenType = TFTokenTypeSymbol;
		for(NSString *symbol in multicharSymbols)
			if([self scanString:symbol]) return symbol;
		location++;
		return [NSString stringWithCharacters:&firstChar length:1];
	}
}


- (BOOL)scanToken:(NSString*)matchToken {
	if([[self peekToken] isEqual:matchToken]) {
		[self scanToken];
		return YES;
	}else return NO;
}


- (BOOL)isAtEnd {
	return location >= [content length];
}


@end