//
//  WSStaticFileHandler.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-11.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WARequestHandler.h"

@interface WAStaticFileHandler : WARequestHandler
@property NSUInteger statusCode;

- (id)initWithFile:(NSString*)path enableCaching:(BOOL)useHTTPCache;

+ (NSString*)mediaTypeForFileExtension:(NSString*)extension;
+ (void)setMediaType:(NSString*)mediaType forFileExtension:(NSString*)extension;
@end