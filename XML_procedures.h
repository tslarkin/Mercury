//
//  XML procedures.h
//  Hernix
//
//  Created by Timothy Larkin on 8/8/07.
//  Copyright 2007 Abstract Tools. All rights reserved.
//

#import "AppController.h"

#if __APPLE__
@interface AppController (XML)
- (void)setupOutputsFromXML:(NSArray*)outputs;
- (void)doInitializations:(NSArray*)inits;
- (void)getRunParameters:(NSString*)setupPath;
- (NSMutableArray*)getSteppers:(NSArray*)stepperxml;

@end
#endif

#if __linux__
#include <GNUstepBase/GSXML.h>
@interface AppController (XML)
- (void)setupOutputsFromXML:(GSXPathNodeSet*)outputs;
- (void)doInitializations:(GSXPathNodeSet*)inits;
- (void)getRunParameters:(NSString*)setupPath;
//- (NSMutableArray*)getSteppers:(NSArray*)stepperxml;

@end

#endif
