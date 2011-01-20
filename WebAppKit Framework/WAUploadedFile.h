//
//  WAUploadedFile.h
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-20.
//  Copyright 2011 Lighthead Software. All rights reserved.
//


@interface WAUploadedFile : NSObject {
	NSString *temporaryFile;
	NSString *parameterName;
	NSString *filename;
	NSString *mediaType;
}

@property(readonly) NSString *temporaryFile;
@property(readonly) NSString *parameterName;
@property(readonly) NSString *filename;
@property(readonly) NSString *mediaType;

- (BOOL)moveToPath:(NSString*)path error:(NSError**)outError;
@end