#import "___PROJECTNAMEASIDENTIFIER___.h"

@implementation ___PROJECTNAMEASIDENTIFIER___


- (void)setup {
	[self addRouteSelector:@selector(index:response:) HTTPMethod:@"GET" path:@"/"];
}


- (id)index:(WARequest*)req response:(WAResponse*)resp {
	WATemplate *t = [WATemplate templateNamed:@"index"];
	[t setValue:@"Hello world" forKey:@"foo"];
	return t;
}


@end