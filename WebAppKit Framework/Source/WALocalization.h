//
//  WSLocalization.h
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-21.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WALocalization : NSObject {
	NSDictionary *mapping;
}

+ (id)localizationNamed:(NSString*)name;
- (id)initWithMapping:(NSDictionary*)dictionary;
- (id)initWithContentsOfFile:(NSString*)file;

- (NSString*)stringForKeyPath:(NSString*)key;

@end