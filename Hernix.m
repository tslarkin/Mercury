#import <Foundation/Foundation.h>
#import "Instantiator.h"
#import "HMPart.h"
#import "AppController.h"

BOOL is10_6 = NO;

int main (int argc, const char * argv[]) {
	if (argc < 2) {
		NSLog(@"No setup file specified");
		return 1;
	}
#if __APPLE__
//	SInt32 versionMajor, versionMinor, versionBugFix;
//	Gestalt(gestaltSystemVersionMajor, &versionMajor);
//	Gestalt(gestaltSystemVersionMinor, &versionMinor);
//	Gestalt(gestaltSystemVersionBugFix, &versionBugFix);	
//	is10_6 = versionMajor == 10 && versionMinor >= 6;
    is10_6 = YES;
#endif
	//is10_6 = NO;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    // insert code here...
	NSString *setupPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
	AppController *controller = [[AppController alloc] init];
	[controller runSimulation:setupPath];
	// Clang suggests
	[controller release];
	[pool release];
    return 0;
}
