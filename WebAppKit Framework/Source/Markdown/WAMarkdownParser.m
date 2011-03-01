//
//  WAMarkdownParser.m
//  mdtest
//
//  Created by Tomas Franzén on 2011-02-02.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAMarkdownParser.h"
#import "markdown.h"

static NSString *StringFromBuf(struct buf *buf) {
	if(!buf) return nil;
	return [[NSString alloc] initWithBytes:buf->data length:buf->size encoding:NSUTF8StringEncoding];
}

static void BufPutString(struct buf *buf, NSString *string) {
	bufputs(buf, [string UTF8String]);
}

#pragma mark libupskirt Callback Functions

static void WAMD_paragraph(struct buf *ob, struct buf *text, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForParagraph:StringFromBuf(text)]);
}

static void WAMD_blockcode(struct buf *ob, struct buf *text, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForBlockCode:StringFromBuf(text)]);
}

static void WAMD_blockquote(struct buf *ob, struct buf *text, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForBlockQuote:StringFromBuf(text)]);
}

static void WAMD_blockhtml(struct buf *ob, struct buf *text, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForBlockHTML:StringFromBuf(text)]);
}

static void WAMD_header(struct buf *ob, struct buf *text, int level, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForHeading:StringFromBuf(text) level:level]);
}

static void WAMD_hrule(struct buf *ob, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter stringForHorizontalRuleWithParser:parser]);
}

static void WAMD_list(struct buf *ob, struct buf *text, int flags, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForList:StringFromBuf(text) ordered:flags & MKD_LIST_ORDERED]);
}

static void WAMD_listitem(struct buf *ob, struct buf *text, int flags, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForListItem:StringFromBuf(text) containingBlock:flags & MKD_LI_BLOCK]);
}

static int WAMD_codespan(struct buf *ob, struct buf *text, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForInlineCode:StringFromBuf(text)]);
	return 1;
}

static int WAMD_emphasis(struct buf *ob, struct buf *text, char c, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForEmphasis:StringFromBuf(text) strength:1 character:c]);
	return 1;
}

static int WAMD_doubleemphasis(struct buf *ob, struct buf *text, char c, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForEmphasis:StringFromBuf(text) strength:2 character:c]);
	return 1;
}

static int WAMD_tripleemphasis(struct buf *ob, struct buf *text, char c, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForEmphasis:StringFromBuf(text) strength:3 character:c]);
	return 1;
}

static int WAMD_image(struct buf *ob, struct buf *link, struct buf *title, struct buf *alt, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForImage:StringFromBuf(link) title:StringFromBuf(title) alternativeText:StringFromBuf(alt)]);
	return 1;
}

static int WAMD_link(struct buf *ob, struct buf *link, struct buf *title, struct buf *content, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter parser:parser stringForLink:StringFromBuf(link) title:StringFromBuf(title) content:StringFromBuf(content)]);
	return 1;
}

static int WAMD_linebreak(struct buf *ob, void *opaque) {
	WAMarkdownParser *parser = (WAMarkdownParser*)opaque;
	BufPutString(ob, [parser.formatter stringForLinebreakWithParser:parser]);
	return 1;
}


@implementation WAMarkdownParser
@synthesize formatter;

- (id)initWithSource:(NSString*)markdown formatter:(id<WAMarkdownFormatter>)object {
	self = [super init];
	formatter = object;
	source = [markdown dataUsingEncoding:NSUTF8StringEncoding];	
	return self;
}

- (NSString*)formattedString {
	struct buf input = {(char*)[source bytes], [source length]};
	struct mkd_renderer renderer = {
		WAMD_blockcode,
		WAMD_blockquote,
		WAMD_blockhtml,
		WAMD_header,
		WAMD_hrule,
		WAMD_list,
		WAMD_listitem,
		WAMD_paragraph,
		
		NULL,
		WAMD_codespan,
		WAMD_doubleemphasis,
		WAMD_emphasis,
		WAMD_image,
		WAMD_linebreak,
		WAMD_link,
		NULL,
		WAMD_tripleemphasis,
		
		NULL,
		NULL,
		
		"_*",
		self
	};
	struct buf *ob = bufnew(10);
	
	markdown(ob, &input, &renderer);
	return StringFromBuf(ob);
}


@end
