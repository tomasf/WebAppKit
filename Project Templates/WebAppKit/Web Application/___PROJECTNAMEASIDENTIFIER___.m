#import "___PROJECTNAMEASIDENTIFIER___.h"

@implementation ___PROJECTNAMEASIDENTIFIER___


- (void)setup {
	[self addRouteSelector:@selector(index) HTTPMethod:@"GET" path:@"/"];
}


- (id)index {
	WATemplate *t = [WATemplate templateNamed:@"index"];
	[t setValue:@"Hello world" forKey:@"foo"];
	return t;
}


@end