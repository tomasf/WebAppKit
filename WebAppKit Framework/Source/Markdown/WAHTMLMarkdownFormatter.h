//
//  WAHTMLMarkdownFormatter.h
//  mdtest
//
//  Created by Tomas Franzén on 2011-02-03.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAMarkdownParser.h"

@interface WAHTMLMarkdownFormatter : NSObject <WAMarkdownFormatter> {}
- (NSString*)HTMLForMarkdown:(NSString*)markdown;
@end
