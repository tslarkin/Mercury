//
//  HMRandom.m
//  Mercury
//
//  Created by Timothy Larkin on 1/28/17.
//
//

#import "HMRandom.h"

@implementation HMRandom

// http://stackoverflow.com/questions/8779843/generating-a-random-gaussian-double-in-objective-c-c

enum { rn_type, rn_mean, rn_sigma };
enum { rn_output };

-(void)updateRates {
    float z;
    if (z2 != nil) {
        z = z2.floatValue;
        [z2 release];
        z2 = nil;
    } else {
        float mean = floatValue([self finalInputValueAt:rn_mean]);
        float sigma = floatValue([self finalInputValueAt:rn_sigma]);
        
        float x1, x2, w;
        
        do {
            x1 = 2.0 * drand48() - 1.0;
            x2 = 2.0 * drand48() - 1.0;
            w = x1 * x1 + x2 * x2;
        } while ( w >= 1.0 );
        
        w = sqrt( (-2.0 * log( w ) ) / w );
        z = sigma * x1 * w + mean;
        z2 = [NSNumber numberWithFloat: sigma * x2 * w + mean];
        [z2 retain];
    }
    setFloatValue([self outputValue:rn_output], z);
}

@end
