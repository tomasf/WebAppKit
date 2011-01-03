//
//  TFRegex.m
//  TFRegexTest
//
//  Created by Tomas Franzén on 2006-07-12.
//  Based on CSRegex by Dag Ågren

#import "TFRegex.h"


@implementation TFRegex
@synthesize source;

- (id)initWithPattern:(NSString*)pattern options:(TFRegexFlags)flags {
	self = [super init];
	
	source = [pattern copy];
	// Convert TFRegexFlags to regex cflags
	int regFlags =	((flags & TFRegexUseBasic) ? REG_BASIC : REG_EXTENDED) |
					((flags & TFRegexCaseInsensitive) ? REG_ICASE : 0) |
					((flags & TFRegexNewLineSensitive) ? REG_NEWLINE : 0);
	
	// Compile expression and throw exception if it fails
	int compileError = regcomp(&expression,[pattern UTF8String],regFlags);
	
	if(compileError) {
		char errorBuffer[256];
		regerror(compileError,&expression,errorBuffer,sizeof(errorBuffer));
		[NSException raise:@"TFRegexCompileException" format:@"Could not compile regular expression \"%@\": %s",pattern,errorBuffer];
	}
	return self;
}


+ (id)regexWithPattern:(NSString*)pattern options:(TFRegexFlags)flags {
	return [[[self alloc] initWithPattern:pattern options:flags] autorelease];
}

- (void)dealloc {
	[source release];
	regfree(&expression);
	[super dealloc];
}


#pragma mark -

- (NSUInteger)subexpressionCount {
	return expression.re_nsub;
}


#pragma mark -

- (BOOL)matchesString:(NSString*)string {
	return (regexec(&expression,[string UTF8String],0,NULL,0)==0);
}

- (NSString*)firstMatchInString:(NSString*)string {
	const char *cString = [string UTF8String];
	regmatch_t match;
	
	if(regexec(&expression,cString,1,&match,0)==0) {
		return [[[NSString alloc] initWithBytes:cString+match.rm_so length:match.rm_eo-match.rm_so encoding:NSUTF8StringEncoding] autorelease];
	}
	return nil;
}


- (NSArray*)matchesInString:(NSString*)string {
	const char *cString = [string UTF8String];
	regmatch_t match;
	NSMutableArray *matches = [NSMutableArray array];
	
	int start = 0;
	while(YES) {
		const char *offsetString = cString + start;
		if(regexec(&expression,offsetString,1,&match,0)==0) {
			NSString *matchString = [[[NSString alloc] initWithBytes:offsetString+match.rm_so length:match.rm_eo-match.rm_so encoding:NSUTF8StringEncoding] autorelease];
			[matches addObject:matchString];
			start += match.rm_eo;
		}else break;
	}
	return matches;
}


- (NSRange)rangeOfFirstMatchInString:(NSString*)string {
	const char *cString = [string UTF8String];
	regmatch_t match;
	
	if(regexec(&expression,cString,1,&match,0)==0)
		return NSMakeRange(match.rm_so, match.rm_so-match.rm_so+1);
	else
		return NSMakeRange(NSNotFound,0);
}

- (BOOL)getRangesOfSubexpressionsOfFirstMatchInString:(NSString*)string, ... {
	const char *cString = [string UTF8String];
	int numSubExpressions = expression.re_nsub + 1;
	regmatch_t matches[numSubExpressions];
	
	if(regexec(&expression, cString, numSubExpressions, matches, 0)!=0)
		return NO;
		
	
	va_list list;
	va_start(list,string);
	
	for(int i=0; i<numSubExpressions; i++) {
		regmatch_t subMatch = matches[i];
		NSRange *outRange = va_arg(list, NSRange*);
		
		if(!outRange) continue;
		if(subMatch.rm_so == -1)
			*outRange = NSMakeRange(NSNotFound, 0);
		else
			*outRange = NSMakeRange(subMatch.rm_so, subMatch.rm_eo-subMatch.rm_so);
	}
	
	va_end(list);
	return YES;
}


- (NSArray*)subExpressionsInMatchesOfString:(NSString*)string {
	const char *cString = [string UTF8String];
	NSMutableArray *matchArray = [NSMutableArray array];
	int numSubExpressions = expression.re_nsub + 1;
	regmatch_t matches[numSubExpressions];
	
	int i, start = 0;
	while(YES) {
		const char *offsetString = cString + start;
		if(regexec(&expression,offsetString,numSubExpressions,matches,0)==0) {
			NSMutableArray *subExprArray = [NSMutableArray arrayWithCapacity:numSubExpressions];
			
			for(i=0; i<numSubExpressions; i++) {
				NSString *subExprString = @"";
				regmatch_t subMatch = matches[i];
				
				if(subMatch.rm_so != -1 && subMatch.rm_eo != -1){
					subExprString = [[[NSString alloc] initWithBytes:offsetString + subMatch.rm_so
						length:subMatch.rm_eo - subMatch.rm_so
						encoding:NSUTF8StringEncoding] autorelease];
				}
				[subExprArray addObject:subExprString];
			}
			
			[matchArray addObject:subExprArray];
			start += matches[0].rm_eo;
		}else break;
	}
	return matchArray;
}




- (BOOL)replaceMatchesInString:(NSMutableString*)string withStringPattern:(NSString*)replacement {
	const char *cString = [string UTF8String];
	int numSubExpressions = expression.re_nsub + 1;
	regmatch_t matches[numSubExpressions];
	
	int i, start = 0;
	while(YES) {
		const char *offsetString = cString + start;
		if(regexec(&expression,offsetString,numSubExpressions,matches,0)==0) {
			NSMutableString *expandedReplacement = [NSMutableString stringWithString:replacement];
			
			for(i=0; i<numSubExpressions; i++) {
				NSString *subExprString = @"";
				regmatch_t subMatch = matches[i];
				
				if(subMatch.rm_so != -1 && subMatch.rm_eo != -1){
					subExprString = [[[NSString alloc] initWithBytes:offsetString + subMatch.rm_so
						length:subMatch.rm_eo - subMatch.rm_so
						encoding:NSUTF8StringEncoding] autorelease];
				}
				
				NSString *escapedChar = [NSString stringWithFormat:@"\\%d",i];
				[expandedReplacement replaceOccurrencesOfString:escapedChar withString:subExprString options:0 range:NSMakeRange(0,[expandedReplacement length])];
			}
			
			NSRange wholeMatchRange = NSMakeRange(matches[0].rm_so + start,matches[0].rm_eo-matches[0].rm_so);
			int enlargement = [expandedReplacement length]-wholeMatchRange.length;
			const char *finalReplacement = [expandedReplacement UTF8String];
			
			char newString[strlen(cString)+enlargement+1];
			memcpy(newString,cString,wholeMatchRange.location);
			memcpy(newString+wholeMatchRange.location, finalReplacement, strlen(finalReplacement));
			memcpy(newString+wholeMatchRange.location+strlen(finalReplacement), cString+wholeMatchRange.location+wholeMatchRange.length, strlen(cString)-wholeMatchRange.location-wholeMatchRange.length);
			newString[strlen(cString)+enlargement] = 0;
			
			cString = [[[[NSString alloc] initWithBytes:newString length:strlen(newString) encoding:NSUTF8StringEncoding] autorelease] UTF8String];
			start += (matches[numSubExpressions-1].rm_eo + enlargement);
		}else break;
	}
	
	[string replaceCharactersInRange:NSMakeRange(0,[string length]) withString:
		[[[NSString alloc] initWithBytes:cString length:strlen(cString) encoding:NSUTF8StringEncoding] autorelease]];
	return YES;
}


- (NSString*)stringWithReplacedMatchesInString:(NSString*)string withStringPattern:(NSString*)replacement {
	NSMutableString *newString = [NSMutableString stringWithString:string];
	[self replaceMatchesInString:newString withStringPattern:replacement];
	return newString;
}


+ (NSString*)escapeString:(NSString*)string {
	NSString *charString = @"\\.+*[](){}";
	for(int i=0; i<[charString length]; i++) {
		unichar c = [charString characterAtIndex:i];
		string = [string stringByReplacingOccurrencesOfString:[NSString stringWithCharacters:&c length:1] withString:[NSString stringWithFormat:@"\\%C", c]];
	}
	return string;
}


@end




@implementation NSString (TFRegex)
- (BOOL)matchedByPattern:(NSString*)pattern {
	return [self matchedByPattern:pattern options:TFRegexNoFlag];
}

- (BOOL)matchedByPattern:(NSString*)pattern options:(TFRegexFlags)flags {
	return [[TFRegex regexWithPattern:pattern options:flags] matchesString:self];
}


- (NSString*)firstMatchWithPattern:(NSString*)pattern {
	return [self firstMatchWithPattern:pattern options:TFRegexNoFlag];
}

- (NSString*)firstMatchWithPattern:(NSString*)pattern options:(TFRegexFlags)flags {
	return [[TFRegex regexWithPattern:pattern options:flags] firstMatchInString:self];
}


- (NSArray*)matchesWithPattern:(NSString*)pattern {
	return [self matchesWithPattern:pattern options:TFRegexNoFlag];
}

- (NSArray*)matchesWithPattern:(NSString*)pattern options:(TFRegexFlags)flags {
	return [[TFRegex regexWithPattern:pattern options:flags] matchesInString:self];
}

- (NSArray*)subExpressionsInMatchesWithPattern:(NSString*)pattern {
		return [self subExpressionsInMatchesWithPattern:pattern options:TFRegexNoFlag];
}

- (NSArray*)subExpressionsInMatchesWithPattern:(NSString*)pattern options:(TFRegexFlags)flags {
	return [[TFRegex regexWithPattern:pattern options:flags] subExpressionsInMatchesOfString:self];
}

- (NSString*)stringByReplacing:(NSString*)pattern with:(NSString*)replacement {
	return [self stringByReplacing:pattern with:replacement options:TFRegexNoFlag];
}

- (NSString*)stringByReplacing:(NSString*)pattern with:(NSString*)replacement options:(TFRegexFlags)flags {
	return [[TFRegex regexWithPattern:pattern options:flags] stringWithReplacedMatchesInString:self withStringPattern:replacement];
}

@end


@implementation NSMutableString (TFRegex)
- (BOOL)replaceMatchesOf:(NSString*)pattern with:(NSString*)replacement {
	return [self replaceMatchesOf:pattern with:replacement options:TFRegexNoFlag];
}

- (BOOL)replaceMatchesOf:(NSString*)pattern with:(NSString*)replacement options:(TFRegexFlags)flags {
	return [[TFRegex regexWithPattern:pattern options:flags] replaceMatchesInString:self withStringPattern:replacement];
}
@end



