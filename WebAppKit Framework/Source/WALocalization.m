//
//  WSLocalization.m
//  WebApp
//
//  Created by Tomas Franzén on 2010-12-21.
//  Copyright 2010 Lighthead Software. All rights reserved.
//

#import "WALocalization.h"


@implementation WALocalization

+ (id)localizationNamed:(NSString*)name {
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
	if(!path) {
		NSLog(@"Warning: Localization '%@' not found.", name);
		return nil;
	}
	return [[self alloc] initWithContentsOfFile:path];
}


- (id)initWithContentsOfFile:(NSString*)file {
	return [self initWithMapping:[NSDictionary dictionaryWithContentsOfFile:file]];
}

- (id)initWithMapping:(NSDictionary*)dictionary {
	self = [super init];
	mapping = [dictionary copy];
	return self;
}

- (NSString*)stringForKeyPath:(NSString*)key {
	NSString *value = [mapping valueForKeyPath:key];
	if(!value) {
		NSLog(@"Warning: Missing localization key %@", key);
		return key;
	}
	return value;
}

@end
