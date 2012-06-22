#import "WebApp.h"

int main(int argc, char *argv[]) {
#ifdef DEBUG
	WASetDevelopmentMode(YES);
#endif
	return WAApplicationMain();
}