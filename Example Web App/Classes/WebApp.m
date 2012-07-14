#import "WebApp.h"

@implementation WebApp


- (id)init {
	if((self = [super init])) {
		[self addRouteSelector:@selector(index) HTTPMethod:@"GET" path:@"/"];
	}
	return self;
}


- (id)index {
	WATemplate *template = [WATemplate templateNamed:@"index"]; // Use index.wat
	[template setValue:@"hello world" forKey:@"foo"];
	return template;
}


@end