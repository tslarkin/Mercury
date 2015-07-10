//
//  HMWeather.h
//  Hernix
//
//  Created by Timothy Larkin on 1/11/15.
//
//

#import "HMPart.h"

@interface HMWeather : HMPart
{
    NSUInteger eoa, ncols;
    NSUInteger baseIndex;
    NSArray *data;
}

-(NSArray*)data;
-(void)setData:(NSArray*)array;

@end
