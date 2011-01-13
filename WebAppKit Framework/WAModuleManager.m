//
//  WAModuleManager.m
//  WebAppKit
//
//  Created by Tomas Franzén on 2011-01-07.
//  Copyright 2011 Lighthead Software. All rights reserved.
//

#import "WAModuleManager.h"
#import "WAModule.h"

@implementation WAModuleManager

+ (id)sharedManager {
	static WAModuleManager *singleton;
	if(!singleton) singleton = [[self alloc] init];
	return singleton;
}


- (WAModule*)moduleForIdentifier:(NSString*)ID {
	return [allModules objectForKey:ID];
}


- (id)init {
	self = [super init];
	allModules = [NSMutableDictionary dictionary];
	
	NSArray *moduleURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"wamodule" subdirectory:nil];
	for(NSURL *URL in moduleURLs) {
		WAModule *module = [[WAModule alloc] initWithBundleURL:URL];
		if(module) [allModules setObject:module forKey:module.identifier];
	}
	
	for(WAModule *module in [allModules allValues])
		for(NSString *dependency in module.dependencies)
			if(![self moduleForIdentifier:dependency])
				NSLog(@"WARNING: No module found for identifier '%@'. '%@' depends on this module.", dependency, module.identifier);
	
	return self;
}


- (void)loadDependenciesForModule:(NSString*)ID withList:(NSMutableArray*)array {
	WAModule *module = [self moduleForIdentifier:ID];
	if([array containsObject:module]) return;
	
	if(!module) {
		NSLog(@"ERROR: Could not find module %@!", ID);
		return;
	}
	
	for(NSString *dependency in module.dependencies)
		[self loadDependenciesForModule:dependency withList:array];
	
	[array addObject:module];
}


- (NSString*)headerStringFromModuleIdentifiers:(NSSet*)IDs {
	NSMutableArray *modules = [NSMutableArray array];
	for(NSString *ID in IDs)
		[self loadDependenciesForModule:ID withList:modules];
	
	NSMutableString *header = [NSMutableString string];
	for(WAModule *module in modules) {
		NSString *resourceRoot = module.baseRequestPath;
		for(NSString *script in module.scripts) {
			script = [resourceRoot stringByAppendingPathComponent:script];
			[header appendFormat:@"<script src=\"%@\" type=\"text/javascript\"></script>", script];
		}
		for(NSString *stylesheet in module.stylesheets) {
			stylesheet = [resourceRoot stringByAppendingPathComponent:stylesheet];
			[header appendFormat:@"<link rel=\"stylesheet\" href=\"%@\" />", stylesheet];
		}
		NSString *additional = module.additionalCode;
		if(additional) [header appendString:additional];
	}
	return header;
}


- (NSSet*)allRequestHandlers {
	NSMutableSet *handlers = [NSMutableSet set];
	for(WAModule *module in [allModules allValues]) {
		WARequestHandler *handler = module.resourcesRequestHandler;
		if(handler) [handlers addObject:handler];
	}
	return handlers;
}


@end
