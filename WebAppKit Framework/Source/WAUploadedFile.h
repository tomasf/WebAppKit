//
//  WAUploadedFile.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//


@interface WAUploadedFile : NSObject
@property(readonly, copy) NSURL *temporaryFileURL;
@property(readonly, copy) NSString *parameterName;
@property(readonly, copy) NSString *filename;
@property(readonly, copy) NSString *mediaType;

- (BOOL)moveToURL:(NSURL*)destination error:(NSError**)outError;
@end