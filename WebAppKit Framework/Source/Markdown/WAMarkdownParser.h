//
//  WAMarkdownParser.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-02-02.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@class WAMarkdownParser;


@protocol WAMarkdownFormatter
- (NSString*)parser:(WAMarkdownParser*)parser stringForParagraph:(NSString*)content;
- (NSString*)parser:(WAMarkdownParser*)parser stringForBlockQuote:(NSString*)content;

- (NSString*)parser:(WAMarkdownParser*)parser stringForInlineCode:(NSString*)code;
- (NSString*)parser:(WAMarkdownParser*)parser stringForBlockCode:(NSString*)code;

- (NSString*)parser:(WAMarkdownParser*)parser stringForInlineHTML:(NSString*)HTML;
- (NSString*)parser:(WAMarkdownParser*)parser stringForBlockHTML:(NSString*)HTML;

- (NSString*)parser:(WAMarkdownParser*)parser stringForList:(NSString*)content ordered:(BOOL)orderedList;
- (NSString*)parser:(WAMarkdownParser*)parser stringForListItem:(NSString*)content containingBlock:(BOOL)isBlock;

- (NSString*)parser:(WAMarkdownParser*)parser stringForHeading:(NSString*)heading level:(NSUInteger)level;
- (NSString*)stringForHorizontalRuleWithParser:(WAMarkdownParser*)parser;
- (NSString*)stringForLinebreakWithParser:(WAMarkdownParser*)parser;

- (NSString*)parser:(WAMarkdownParser*)parser stringForLink:(NSString*)target title:(NSString*)title content:(NSString*)content;
- (NSString*)parser:(WAMarkdownParser*)parser stringForImage:(NSString*)src title:(NSString*)title alternativeText:(NSString*)alt;
- (NSString*)parser:(WAMarkdownParser*)parser stringForEmphasis:(NSString*)content strength:(NSUInteger)level character:(unichar)c;
@end



@interface WAMarkdownParser : NSObject {
	id<WAMarkdownFormatter> formatter;
	NSData *source;
}

@property(readonly) NSString *formattedString;
@property(assign) id<WAMarkdownFormatter> formatter;

- (id)initWithSource:(NSString*)markdown formatter:(id<WAMarkdownFormatter>)object;
@end
