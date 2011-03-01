//
//  WAHTMLMarkdownFormatter.m
//  mdtest
//
//  Created by Tomas Franzén on 2011-02-03.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAHTMLMarkdownFormatter.h"



@implementation WAHTMLMarkdownFormatter

- (NSString*)parser:(WAMarkdownParser*)parser stringForParagraph:(NSString*)content {
	return [NSString stringWithFormat:@"<p>%@</p>", content];
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForBlockQuote:(NSString*)content {
	return [NSString stringWithFormat:@"<blockquote>%@</blockquote>", content];	
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForInlineCode:(NSString*)code {
	return [NSString stringWithFormat:@"<code>%@</code>", [code HTMLEscapedString]];	
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForBlockCode:(NSString*)code {
	return [NSString stringWithFormat:@"<pre><code>%@</code></pre>", [code HTMLEscapedString]];	
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForInlineHTML:(NSString*)HTML {
	return [NSString stringWithFormat:@"%@", HTML];
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForBlockHTML:(NSString*)HTML {
	return [NSString stringWithFormat:@"<div>%@</div>", HTML];
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForList:(NSString*)content ordered:(BOOL)orderedList {
	NSString *element = (orderedList ? @"ol" : @"ul");
	return [NSString stringWithFormat:@"<%@>%@</%@>", element, content, element];
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForListItem:(NSString*)content containingBlock:(BOOL)isBlock {
	return [NSString stringWithFormat:@"<li>%@</li>", content];
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForHeading:(NSString*)heading level:(NSUInteger)level {
	return [NSString stringWithFormat:@"<h%d>%@</h%d>", (int)level, heading, (int)level];	
}

- (NSString*)stringForHorizontalRuleWithParser:(WAMarkdownParser*)parser {
	return @"<hr/>";
}

- (NSString*)stringForLinebreakWithParser:(WAMarkdownParser*)parser {
	return @"<br/>";
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForLink:(NSString*)target title:(NSString*)title content:(NSString*)content {
	title = title ? [NSString stringWithFormat:@" title=\"%@\"", title] : @"";
	return [NSString stringWithFormat:@"<a href=\"%@\"%@>%@</a>", target, title, content];	
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForImage:(NSString*)src title:(NSString*)title alternativeText:(NSString*)alt {
	title = title ? [NSString stringWithFormat:@" title=\"%@\"", title] : @"";
	alt = alt ? [NSString stringWithFormat:@" alt=\"%@\"", alt] : @"";
	return [NSString stringWithFormat:@"<img src=\"%@\"%@%@/>", src, alt, title];	
}

- (NSString*)parser:(WAMarkdownParser*)parser stringForEmphasis:(NSString*)content strength:(NSUInteger)level character:(unichar)c {
	switch(level) {
		case 1: return [NSString stringWithFormat:@"<em>%@</em>", content];
		default: 
		case 2: return [NSString stringWithFormat:@"<strong>%@</strong>", content];
	}
}


- (NSString*)HTMLForMarkdown:(NSString*)markdown {
	WAMarkdownParser *parser = [[WAMarkdownParser alloc] initWithSource:markdown formatter:self];
	return parser.formattedString;
}

@end
