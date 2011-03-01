//
//  WAMarkdown.h
//  mdtest
//
//  Created by Tomas Franzén on 2011-02-03.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

@interface NSString (WAMarkdown)
- (NSString*)HTMLFromMarkdown;
@end

@interface WAMarkdown : NSObject {}
+ (NSString*)HTMLFromMarkdownFileNamed:(NSString*)name;
@end