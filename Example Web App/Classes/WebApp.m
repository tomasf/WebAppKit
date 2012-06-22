#import "WebApp.h"

@implementation WebApp


- (void)setup {
	// -setup is run on launch. Here, you can declare routes, set up Core Data MOCs, load resources, etc.
	[self addRouteSelector:@selector(index) HTTPMethod:@"GET" path:@"/"];
}


- (id)index {
	WATemplate *template = [WATemplate templateNamed:@"index"]; // Use index.wat
	[template setValue:@"hello world" forKey:@"foo"];
	return template;
}


@end