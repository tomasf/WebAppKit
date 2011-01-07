//
//  WAModule.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-07.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAModule.h"
#import "WARequestHandler.h"
#import "WADirectoryHandler.h"

static const NSString *WAModuleScriptsKey = @"WAModuleScripts";
static const NSString *WAModuleStylesheetsKey = @"WAModuleStylesheets";
static const NSString *WAModuleDependenciesKey = @"WAModuleDependencies";


@implementation WAModule

- (id)initWithBundleURL:(NSURL*)URL {
	self = [super init];
	bundle = [NSBundle bundleWithURL:URL];
	info = [[bundle infoDictionary] copy];
	[bundle load];
	return self;
}

- (NSString*)identifier {
	return [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension];
}

- (NSString*)publicResourceDirectory {
	return [bundle pathForResource:@"public" ofType:nil];
}

- (NSString*)baseRequestPath {
	return [NSString stringWithFormat:@"/module/%@", self.identifier];
}

- (NSArray*)dependencies {
	return [info objectForKey:WAModuleDependenciesKey];
}

- (NSArray*)scripts {
	return [info objectForKey:WAModuleScriptsKey];
}

- (NSArray*)stylesheets {
	return [info objectForKey:WAModuleStylesheetsKey];
}

- (WARequestHandler*)resourcesRequestHandler {
	if(!self.publicResourceDirectory) return nil;
	return [[WADirectoryHandler alloc] initWithDirectory:self.publicResourceDirectory requestPath:self.baseRequestPath];
}

@end