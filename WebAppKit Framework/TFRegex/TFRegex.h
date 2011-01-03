//
//  TFRegex.h
//  TFRegexTest
//
//  Created by Tomas Franzén on 2006-07-12.
//  Copyright 2006 Lighthead Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <regex.h>


typedef enum {
	TFRegexNoFlag			= 0,
	TFRegexUseBasic			= 1,
	TFRegexCaseInsensitive	= 2,
	TFRegexNewLineSensitive	= 4,
} TFRegexFlags;



@interface TFRegex : NSObject {
	NSString *source;
	regex_t expression;
}

@property(readonly) NSUInteger subexpressionCount;
@property(readonly) NSString *source;

- (id)initWithPattern:(NSString*)pattern options:(TFRegexFlags)flags;
+ (id)regexWithPattern:(NSString*)pattern options:(TFRegexFlags)flags;

- (BOOL)matchesString:(NSString*)string;
- (NSString*)firstMatchInString:(NSString*)string;
- (NSArray*)matchesInString:(NSString*)string;

- (NSRange)rangeOfFirstMatchInString:(NSString*)string;
- (BOOL)getRangesOfSubexpressionsOfFirstMatchInString:(NSString*)string, ...;

- (NSArray*)subExpressionsInMatchesOfString:(NSString*)string;
- (BOOL)replaceMatchesInString:(NSMutableString*)string withStringPattern:(NSString*)replacement;
- (NSString*)stringWithReplacedMatchesInString:(NSString*)string withStringPattern:(NSString*)replacement;

+ (NSString*)escapeString:(NSString*)string;
@end



@interface NSString (TFRegex)
- (BOOL)matchedByPattern:(NSString*)pattern;
- (BOOL)matchedByPattern:(NSString*)pattern options:(TFRegexFlags)flags;

- (NSString*)firstMatchWithPattern:(NSString*)pattern;
- (NSString*)firstMatchWithPattern:(NSString*)pattern options:(TFRegexFlags)flags;

- (NSArray*)matchesWithPattern:(NSString*)pattern;
- (NSArray*)matchesWithPattern:(NSString*)pattern options:(TFRegexFlags)flags;

- (NSArray*)subExpressionsInMatchesWithPattern:(NSString*)pattern;
- (NSArray*)subExpressionsInMatchesWithPattern:(NSString*)pattern options:(TFRegexFlags)flags;

- (NSString*)stringByReplacing:(NSString*)pattern with:(NSString*)replacement;
- (NSString*)stringByReplacing:(NSString*)pattern with:(NSString*)replacement options:(TFRegexFlags)flags;
@end


@interface NSMutableString (TFRegex)
- (BOOL)replaceMatchesOf:(NSString*)pattern with:(NSString*)replacement;
- (BOOL)replaceMatchesOf:(NSString*)pattern with:(NSString*)replacement options:(TFRegexFlags)flags;
@end