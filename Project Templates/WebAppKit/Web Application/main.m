#import "___PROJECTNAMEASIDENTIFIER___.h"

int main(int argc, char *argv[]) {
#ifdef DEBUG
	WASetDevelopmentMode(YES);
#endif
	return WAApplicationMain();
}