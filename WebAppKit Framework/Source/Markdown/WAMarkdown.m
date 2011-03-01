//
//  WAMarkdown.m
//  mdtest
//
//  Created by Tomas Franzén on 2011-02-03.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAMarkdown.h"
#import "WAHTMLMarkdownFormatter.h"

@implementation NSString (WAMarkdown)

- (NSString*)HTMLFromMarkdown {
	return [[[WAHTMLMarkdownFormatter alloc] init] HTMLForMarkdown:self];
}

@end


@implementation WAMarkdown

+ (NSString*)HTMLFromMarkdownFileNamed:(NSString*)name {
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"markdown"];
	if(!path) return nil;
	NSString *markdown = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	if(!markdown) return nil;
	return [[[WAHTMLMarkdownFormatter alloc] init] HTMLForMarkdown:markdown];
}

@end