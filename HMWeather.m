//
//  HMWeather.m
//  Hernix
//
//  Created by Timothy Larkin on 1/11/15.
//
//

#import "HMWeather.h"
#import "HMOutput.h"

@implementation HMWeather

-(NSArray*)data
{
    return data;
}

-(void)setData:(NSArray*)array
{
    [data release];
    data = array;
    [data retain];
}

-(void)initialize
{
    [super initialize];
    baseIndex = 1;
    eoa = data.count;
    ncols = ((NSArray*)data[0]).count;
}

- (void)reportEOA
{
    NSValue *v = [[self finalInputValues] objectAtIndex:0];
    Value *val = (Value*)[v pointerValue];
    char *path = pathValue(val);
    NSException *e = [NSException exceptionWithName:@"Simulation forced to end"
                                             reason:[NSString stringWithFormat:@"End of file reached in file %s", path]
                                           userInfo:nil];
    [e raise];
}

-(NSTimeInterval)findLatestStartTime:(NSTimeInterval)start
{
    NSTimeInterval zero = ((NSNumber*)data[1][0]).doubleValue;
    return zero;
}

-(void)updateRates
{
    extern HMOutput *gTime;
    NSTimeInterval currentTime = floatValue([gTime value]);
    NSUInteger top = baseIndex;
    while (top < eoa && ((NSNumber*)data[top][0]).floatValue < currentTime) {
        top++;
    }
    if (top == eoa) {
        [self reportEOA];
    }
    if (baseIndex < top) {
        baseIndex = top - 1;
    }
    
    float t1 = ((NSNumber*)data[baseIndex][0]).floatValue, t2 = ((NSNumber*)data[top][0]).floatValue;
    
    float delta = 0.0;
    if (t2 > t1) {
        delta = (currentTime - t1) / (t2 - t1);
    }
    
    for (int i = 1; i < ncols; i++) {
        float z1 = ((NSNumber*)data[baseIndex][i]).floatValue;
        float diff = ((NSNumber*)data[top][i]).floatValue - z1;
        HMOutput *output = outputs[i - 1];
        float z = z1 + diff * delta;
        setFloatValue([output value], z);
    }
    
}

@end
